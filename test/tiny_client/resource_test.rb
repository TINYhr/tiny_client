require 'test_helper'
require 'dummy/post'

describe TinyClient::Resource do

  describe 'Dummy Post project' do

    let(:post) { Dummy::Post.new }

    it { post.path.must_equal 'posts' }
    it { post.must_respond_to :id }
    it { post.must_respond_to :name }
    it { post.must_respond_to :content }

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
      end
    end
  end
end
