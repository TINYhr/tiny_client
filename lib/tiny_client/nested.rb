module TinyClient
  #
  # Mixin that add support for nested resource to {TinyClient::Resource}
  #
  # Each nested resource will be accessible with:
  #    add_<resource_name>(resource) # To create a new one
  #    <resource_name>s              # List the existing     ( get )
  #    all_<resource_name>s          # List all the existing ( buffered by limit )
  #    <resource_name>s_in_batches   # List all in bactches  ( batch size is limit )
  module Nested
    def self.included(resource_class)
      raise ArgumentError, 'Works only for TinyClient::Resource' unless resource_class <= Resource
      resource_class.extend(ClassMethods)
    end

    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    def get_nested(resource_class, params = {})
      self.class.get(params, @id, resource_class.path, resource_class)
    end

    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    def get_nested_all(resource_class, params = {})
      self.class.get_all(params, @id, resource_class.path, resource_class)
    end

    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    def get_nested_in_batches(resource_class, params = {})
      self.class.get_in_batches(params, @id, resource_class.path, resource_class)
    end

    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    def create_nested(resource)
      raise ArgumentError, 'resource must be an TinyClient::Resource' unless resource.is_a? Resource
      data = { resource.class.low_name => resource.to_h }
      self.class.post(data, @id, resource.class.path, resource.class)
    end

    # Add support for the {#nested} class methods as well as default actions.
    module ClassMethods
      attr_reader :nested

      # Set nested resources. Nested resource creation and getters method will be created.
      # If the resource class is called Post, then {add_post} and {posts} methods will be created.
      # @param [Resource] clazz the nested resource class.
      def nested(*clazz)
        @nested ||= nested_actions(clazz) && clazz
      end

      private

      def nested_actions(nested)
        nested.each do |clazz|
          class_eval <<-RUBY
            def #{clazz.low_name}s(params = {}); get_nested(#{clazz}, params) end
            def all_#{clazz.low_name}s(params = {}); get_nested_all(#{clazz}, params) end
            def #{clazz.low_name}s_in_batches(params = {}); get_nested_in_batches(#{clazz}, params) end
            def add_#{clazz.low_name}(resource); create_nested(resource) end
          RUBY
        end
      end
    end
  end
end
