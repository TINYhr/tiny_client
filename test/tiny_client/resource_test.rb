require 'test_helper'

describe TinyClient::Resource do
  TestResource = Class.new(TinyClient::Resource)
  before { TestResource.fields :id, 'name', :extra }
  let(:resource) { TestResource.new }

  it { TestResource.must_respond_to :path }
  it { TestResource.must_respond_to :fields }

  it { TestResource.must_respond_to :low_name }

  it { TestResource.must_respond_to :get }
  it { TestResource.must_respond_to :index }
  it { TestResource.must_respond_to :show }
  it { TestResource.must_respond_to :update }
  it { TestResource.must_respond_to :delete }
  it { TestResource.must_respond_to :post }
  it { TestResource.must_respond_to :put }

  describe '#self.build' do
    it { TestResource.build({}).must_be_instance_of TestResource }
    it { TestResource.build(id: 1).id.must_equal 1 }
    it { TestResource.build('id' => 1).id.must_equal 1 }
    it { proc { TestResource.build(random: '').random }.must_raise NoMethodError }
  end

  describe '#self.fields' do
    let(:resource) { TestResource.new }

    it { resource.must_respond_to :id }
    it { resource.must_respond_to :name }
    it { resource.must_respond_to :extra }
  end

  describe '#self.build' do
    describe 'when hash params contains non specified fiels' do
      let(:resource) { TestResource.build(id: 1, name: 'toto', extra: { age: 23 }) }

      it { resource.id.must_equal 1 }
      it { resource.name.must_equal 'toto' }
      it { resource.extra.must_equal age: 23 }
    end
  end
end
