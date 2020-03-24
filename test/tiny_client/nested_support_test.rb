require 'test_helper'

describe TinyClient::NestedSupport do
  Parent = Class.new(TinyClient::Resource)
  Child = Class.new(TinyClient::Resource)

  let(:resource) { Parent.new }

  it { _(Parent).must_respond_to :nested }

  it { _(resource).must_respond_to :nested_index }
  it { _(resource).must_respond_to :nested_show }
  it { _(resource).must_respond_to :nested_create }
  it { _(resource).must_respond_to :nested_update }
  it { _(resource).must_respond_to :nested_delete }
  it { _(resource).must_respond_to :nested_all } # pagination

  describe 'ClassMethods#nested_index' do
    it 'properly delegate to Resource#get' do
      Parent.expects(:get).with({}, resource.id, Child.path, Child).returns(Child.new)
      _(resource.nested_index(Child, {})).must_be_instance_of Child
    end

    it { _ { resource.nested_index(String, {}) }.must_raise ArgumentError }
  end

  describe 'ClassMethods#nested_all' do
    it 'properly delegate to PaginationSupport#get_all' do
      Parent.expects(:get_all).with({}, resource.id, Child.path, Child).returns(Child.new)
      _(resource.nested_all(Child, {})).must_be_instance_of Child
    end

    it { _ { resource.nested_all(String, {}) }.must_raise ArgumentError }
  end

  describe 'when we add a nested resource' do
    before { Parent.nested Child }

    it { _(Parent.nested).must_equal [Child] }

    it { _(resource).must_respond_to :children }
    it { _(resource).must_respond_to :child }
    it { _(resource).must_respond_to :add_child }
    it { _(resource).must_respond_to :update_child }
    it { _(resource).must_respond_to :remove_child }
    it { _(resource).must_respond_to :children_all }
  end

  describe 'when we add a nested resource has more than a word in its name' do
    Role            = Class.new(TinyClient::Resource)
    AppPermission   = Class.new(TinyClient::Resource)
    MyAppPermission = Class.new(TinyClient::Resource)

    let(:resource) { Role.new }

    before { Role.nested AppPermission, MyAppPermission }

    it 'has correct methods' do
      _(Role.nested).must_equal [AppPermission, MyAppPermission]

      _(resource).must_respond_to :app_permissions
      _(resource).must_respond_to :app_permission
      _(resource).must_respond_to :add_app_permission
      _(resource).must_respond_to :update_app_permission
      _(resource).must_respond_to :remove_app_permission
      _(resource).must_respond_to :app_permissions_all

      _(resource).must_respond_to :my_app_permissions
      _(resource).must_respond_to :my_app_permission
      _(resource).must_respond_to :add_my_app_permission
      _(resource).must_respond_to :update_my_app_permission
      _(resource).must_respond_to :remove_my_app_permission
      _(resource).must_respond_to :my_app_permissions_all
    end
  end
end
