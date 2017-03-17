require 'test_helper'

describe TinyClient::Resource do
  MyResource = Class.new(TinyClient::Resource)
  let(:resource) { MyResource.new }

  it { MyResource.must_respond_to :path }
  it { MyResource.must_respond_to :fields }

  it { MyResource.must_respond_to :low_name }

  it { MyResource.must_respond_to :get }
  it { MyResource.must_respond_to :index }
  it { MyResource.must_respond_to :show }
  it { MyResource.must_respond_to :update }
  it { MyResource.must_respond_to :delete }
  it { MyResource.must_respond_to :post }
  it { MyResource.must_respond_to :put }

  describe '#self.build' do
    before { MyResource.fields :id, :name, :toto }

    it { MyResource.build({}).must_be_instance_of MyResource }
    it { MyResource.build(id: 1).id.must_equal 1 }
    it { MyResource.build('id' => 1).id.must_equal 1 }
    it { proc { MyResource.build(random: '').random }.must_raise NoMethodError }
  end
end
