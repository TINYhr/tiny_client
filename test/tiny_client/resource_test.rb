require 'test_helper'

describe TinyClient::Resource do
  TestResource = Class.new(TinyClient::Resource)
  before { TestResource.fields :id, 'name', :extra, 'bool' }
  let(:resource) { TestResource.new }

  it { _(TestResource).must_respond_to :path }
  it { _(TestResource).must_respond_to :fields }

  it { _(TestResource).must_respond_to :low_name }

  it { _(TestResource).must_respond_to :get }
  it { _(TestResource).must_respond_to :index }
  it { _(TestResource).must_respond_to :show }
  it { _(TestResource).must_respond_to :update }
  it { _(TestResource).must_respond_to :delete }
  it { _(TestResource).must_respond_to :post }
  it { _(TestResource).must_respond_to :put }

  describe '#self.build' do
    it { _(TestResource.build({})).must_be_instance_of TestResource }
    it { _(TestResource.build(id: 1).id).must_equal 1 }
    it { _(TestResource.build('id' => 1).id).must_equal 1 }
    it { _ { TestResource.build(random: '').random }.must_raise NoMethodError }
  end

  describe '#self.fields' do
    let(:resource) { TestResource.new }

    it { _(resource).must_respond_to :id }
    it { _(resource).must_respond_to :name }
    it { _(resource).must_respond_to :extra }
  end

  describe '#self.build' do
    describe 'when hash params contains non specified fiels' do
      let(:resource) { TestResource.build(id: 1, name: 'toto', extra: { age: 23 }, 'bool' => false) }

      it { _(resource.id).must_equal 1 }
      it { _(resource.name).must_equal 'toto' }
      it { _(resource.extra).must_equal(age: 23) }
      it { _(resource.bool).must_equal false }
    end
  end
end
