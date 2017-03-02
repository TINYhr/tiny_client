require 'test_helper'
require 'dummy/post'
require 'dummy/author'

describe TinyClient do
  describe 'Dummy Author' do
    let(:author) { Dummy::Author.new }

    it { author.class.nested.must_equal [Dummy::Post] }
    it { author.must_respond_to :add_post }
    it { author.must_respond_to :posts }

    describe '#posts' do
      let(:posts) { [{ id: 1, name: 'toto' }] }
      let(:response) { author.posts }
      before do
        author.id = 1
        stub_request(:get, Dummy::Config.instance.url + '/authors/1/posts.json').to_return(body: posts.to_json)
        response
      end

      it { response.count.must_equal 1 }
      it { response.first.must_be_instance_of Dummy::Post }
      it { response.first.to_h.must_equal posts[0] }
    end
  end

  describe 'Dummy Post' do
    let(:post) { Dummy::Post.new }

    it { Dummy::Post.path.must_equal 'posts' }
    it { Dummy::Post.fields.must_equal [:id, :name, :content] }
    it { post.must_respond_to :id }
    it { post.must_respond_to :name }
    it { post.must_respond_to :content }

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
        it { response.must_be_instance_of Dummy::Post }
        it { response.name.must_equal post.name }
        it { response.content.must_equal post.content }
        it 'make a post request on the resource path with json content' do
          assert_requested :post, Dummy::Config.instance.url + '/posts.json',
                           body: { post: post.to_h }.to_json, headers: { 'Content-Type' => 'application/json' }
        end
      end
    end

    describe '#self.create' do
      let(:body) { { post: { id: 1, name: 'tata', content: 'blabla' } } }
      let(:response) { Dummy::Post.create(body) }
      before do
        stub_request(:post, Dummy::Config.instance.url + '/posts.json').to_return(body: '{}')
        response
      end

      it { response.must_be_instance_of Dummy::Post }
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

        it { subject.count.must_equal 3 }
        it { subject.first.must_be_instance_of Dummy::Post }
        it { subject.first.to_h.must_equal posts[0] }
      end

      describe '#self.show(1)' do
        before { stub_request(:get, Dummy::Config.instance.url + '/posts/1.json').to_return(body: posts[0].to_json) }

        subject { Dummy::Post.show(1) }

        it { subject.must_be_instance_of Dummy::Post }
        it { subject.to_h.must_equal posts[0] }
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