# frozen_string_literal: true
require 'test_helper'
require 'dummy/post'
require 'dummy/author'

describe TinyClient do
  describe 'Dummy Author' do
    let(:author) { Dummy::Author.new }

    it { _(author.class.nested).must_equal [Dummy::Post] }
    it { _(author).must_respond_to :add_post }
    it { _(author).must_respond_to :posts }

    describe '#posts' do
      let(:posts) { [{ id: 1, name: 'toto' }] }
      let(:response) { author.posts }
      before do
        author.id = 1
        stub_request(:get, Dummy::Config.instance.url + '/authors/1/posts.json').to_return(body: posts.to_json)
        response
      end

      it { _(response.count).must_equal 1 }
      it { _(response.first).must_be_instance_of Dummy::Post }
      it { _(response.first.as_json).must_equal('id' => 1, 'name' => 'toto', 'content' => nil) }
    end

    describe '#add_post' do
      let(:post) { Dummy::Post.new('toto', 'tata') }
      let(:response) { author.add_post(post) }

      describe 'when api return the added post' do
        before do
          author.id = 1
          stub_request(:post, Dummy::Config.instance.url + '/authors/1/posts.json').to_return(body: post.to_json)
        end

        it { _(response).must_be_instance_of Dummy::Post }
        it { _(response.name).must_equal post.name }
        it { _(response.content).must_equal post.content }
        it 'create a new post for this author' do
          response
          assert_requested :post, "#{Dummy::Config.instance.url}/authors/1/posts.json",
                           body: { post: post.as_json(only: post.changes) }.to_json
        end
      end

      describe 'when api return no content' do
        before do
          author.id = 1
          stub_request(:post, Dummy::Config.instance.url + '/authors/1/posts.json').to_return(body: '', status: 204)
          response
        end

        it { _(response).must_be_nil }
        it { _(Dummy::Post.last_response.status).must_equal '204' }
      end
    end

    describe '#self.show(1)' do
      let(:author1) { { name: 'P.K.D', info: { birthday: Date.new(1928, 12, 16), gender: 'male' } } }

      let(:resource) { Dummy::Author.show(1) }

      before do
        ActiveSupport.parse_json_times = true # I want to convert time/date looking string
        stub_request(:get, Dummy::Config.instance.url + '/authors/1.json').to_return(body: author1.to_json)
      end

      it { _(resource.birthday).must_equal author1[:info][:birthday] }
      it { _(resource.name).must_equal author1[:name] }
      it { _(resource.info).must_equal author1[:info].stringify_keys }
    end
  end

  describe 'Dummy Post' do
    let(:post) { Dummy::Post.new }

    it { _(Dummy::Post.path).must_equal 'posts' }
    it { _(Dummy::Post.fields).must_equal [:id, :name, :content] }
    it { _(post).must_respond_to :id }
    it { _(post).must_respond_to :name }
    it { _(post).must_respond_to :content }

    describe '#save!' do
      let(:response) { post.save! }

      describe 'when the post have no id' do
        before do
          post.name = 'toto'
          post.content = 'tata'
          stub_request(:post, Dummy::Config.instance.url + '/posts.json')
            .to_return(body: post.to_json)
          response
        end
        it { _(response).must_be_instance_of Dummy::Post }
        it { _(response.name).must_equal post.name }
        it { _(response.content).must_equal post.content }
        it { _(response.changes).must_respond_to(:empty?) }
        it 'make a post request on the resource path with json content' do
          assert_requested :post, Dummy::Config.instance.url + '/posts.json',
                           body: { post: { name: 'toto', content: 'tata' } }.to_json, headers: { 'Content-Type' => 'application/json' }
        end
      end
    end

    describe '#destroy!' do
      let(:destroy!) { post.destroy! }

      before { stub_request(:delete, Dummy::Config.instance.url + '/posts/1.json').to_return(status: 204) }

      describe 'when the post have an id' do
        before { post.id = 1 }
        it { _(destroy!).must_equal post }
        it 'call delete on the post resource' do
          destroy!
          assert_requested :delete, Dummy::Config.instance.url + '/posts/1.json'
        end
      end
      describe 'when the post does not have an id' do
        before { post.id = nil }

        it { _ { destroy! }.must_raise TinyClient::ResourceError }
      end
    end

    describe '#self.create' do
      let(:body) { { post: { id: 1, name: 'tata', content: 'blabla' } } }
      let(:response) { Dummy::Post.create(body[:post]) }
      before do
        stub_request(:post, Dummy::Config.instance.url + '/posts.json').to_return(body: {}.to_json)
        response
      end

      it { _(response).must_be_instance_of Dummy::Post }
      it do
        assert_requested :post, Dummy::Config.instance.url + '/posts.json',
                         body: body.to_json, headers: { 'Content-Type' => 'application/json' }
      end
    end

    describe 'there are 3 post on the dummy server' do
      let(:posts) { (1..3).each_with_object([]) { |i, arr| arr << { id: i, name: "post#{i}", content: 'lksdfaklsjfdlkasjfd' } } }

      describe '#self.index' do
        before { stub_request(:get, Dummy::Config.instance.url + '/posts.json').to_return(body: posts.to_json) }
        subject { Dummy::Post.index }

        it { _(subject.count).must_equal 3 }
        it { _(subject.first).must_be_instance_of Dummy::Post }
        it { _(subject.first.as_json).must_equal posts[0].stringify_keys }
      end

      describe '#self.show(1)' do
        before { stub_request(:get, Dummy::Config.instance.url + '/posts/1.json').to_return(body: posts[0].to_json) }

        subject { Dummy::Post.show(1) }

        it { _(subject).must_be_instance_of Dummy::Post }
        it { _(subject.as_json).must_equal posts[0].stringify_keys }
        it 'request with proper headers' do
          subject
          assert_requested :get, Dummy::Config.instance.url + '/posts/1.json',
                           headers: { 'Accept' => 'application/json',
                                      'Content-Type' => 'application/x-www-form-urlencoded' }
        end
      end

      describe '#self.show(1) with gzip content' do
        before { stub_request(:get, Dummy::Config.instance.url + '/posts/1.json').to_return(body: ActiveSupport::Gzip.compress(posts[0].to_json), headers: { 'Content-Encoding' => 'gzip' }) }

        subject { Dummy::Post.show(1) }

        it { _(subject).must_be_instance_of Dummy::Post }
        it { _(subject.as_json).must_equal posts[0].stringify_keys }
        it 'request with proper headers' do
          subject
          assert_requested :get, Dummy::Config.instance.url + '/posts/1.json',
                           headers: { 'Accept' => 'application/json',
                                      'Content-Type' => 'application/x-www-form-urlencoded' }
        end
      end
    end
  end
end
