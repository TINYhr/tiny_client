require 'active_support/inflector'

module TinyClient
  #
  # Mixin that add support for nested resource to {TinyClient::Resource}
  # Each nested resource will be accessible with:
  #    <resource_name>s                 # List the existing     ( index )
  #    <resource_name>(id)              # Show an existing      ( show )
  #    add_<resource_name>(resource)    # To create a new one   ( post )
  #    remove_<resource_name>(resource) # Remove an existing    ( delete )
  #    update_<resource_name>(resource) # Update an existing    ( put )
  # @see file:README.md#label-Nested+resource README - Nested Resource
  module NestedSupport
    # @raise [ArgumentError] if the given resource_class is not a Resource
    def self.included(resource_class)
      raise ArgumentError, 'Works only for TinyClient::Resource' unless resource_class <= Resource
      resource_class.extend(ClassMethods)
    end

    # @raise [ArgumentError] if the given resource_class is not a Resource
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    def nested_show(resource_class, id, params = {})
      raise ArgumentError, 'Works only for TinyClient::Resource' unless resource_class <= Resource
      path = UrlBuilder.url(resource_class.path).path(id).build!
      self.class.get(params, @id, path, resource_class)
    end

    # @raise [ArgumentError] if the given resource_class is not a Resource
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    def nested_index(resource_class, params = {})
      raise ArgumentError, 'Works only for TinyClient::Resource' unless resource_class <= Resource
      self.class.get(params, @id, resource_class.path, resource_class)
    end

    # @raise [ArgumentError] if the given resource does not have an id or is not Resource instance
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    def nested_update(resource)
      raise ArgumentError, 'resource must be an TinyClient::Resource' unless resource.is_a? Resource
      raise ArgumentError, 'resource must have id set' if resource.id.nil?
      path = UrlBuilder.url(resource.class.path).path(resource.id).build!
      data = resource.changes.to_a.each_with_object({}) { |fld, h| h[fld] = resource.send(fld) }
      self.class.put({ resource.class.low_name => data }, @id, path, resource.class)
    end

    # @raise [ArgumentError] if the given resource does not have an id or is not a Resource instance
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    def nested_delete(resource)
      raise ArgumentError, 'resource must be an TinyClient::Resource' unless resource.is_a? Resource
      raise ArgumentError, 'resource must have id set' if resource.id.nil?
      path = UrlBuilder.url(resource.class.path).path(resource.id).build!
      self.class.delete(@id, path, resource.class)
    end

    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    def nested_create(resource)
      raise ArgumentError, 'resource must be an TinyClient::Resource' unless resource.is_a? Resource
      data = resource.changes.to_a.each_with_object({}) { |fld, h| h[fld] = resource.send(fld) }
      self.class.post({ resource.class.low_name => data }, @id, resource.class.path, resource.class)
    end

    # @see PaginationSupport::ClassMethods.get_all
    # @raise [ArgumentError] if the given resource_class is not a Resource
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    def nested_all(resource_class, params = {})
      raise ArgumentError, 'Works only for TinyClient::Resource' unless resource_class <= Resource
      self.class.get_all(params, @id, resource_class.path, resource_class)
    end

    # Add support for the {#nested} class methods as well as default actions.
    module ClassMethods
      # Set nested resources. Nested resource creation and getters method will be created.
      # If the resource class is called Post, then `add_post` and `posts` methods will be created.
      # @param [Resource] clazz the nested resource class.
      def nested(*clazz)
        @nested ||= nested_actions(clazz) && clazz
      end

      private

      def nested_actions(nested)
        nested.each do |clazz|
          plural_name = ActiveSupport::Inflector.pluralize(clazz.low_name)
          class_eval <<-RUBY
            def #{plural_name}(params = {}); nested_index(#{clazz}, params) end
            def #{clazz.low_name}(id, params = {}); nested_show(#{clazz}, id, params) end
            def add_#{clazz.low_name}(#{clazz.low_name}); nested_create(#{clazz.low_name}) end
            def update_#{clazz.low_name}(#{clazz.low_name}); nested_update(#{clazz.low_name}) end
            def remove_#{clazz.low_name}(#{clazz.low_name}); nested_delete(#{clazz.low_name}) end
            def #{plural_name}_all(params = {}); nested_all(#{clazz}, params) end
          RUBY
        end
      end
    end
  end
end
