require 'set'
require 'active_support/json'
require 'active_support/core_ext/object/json'
module TinyClient
  # This is the core of TinyClient.
  # Subclass {TinyClient::Resource} in order to create an HTTP/JSON tiny client.
  #
  # {file:README.md Getting Started}
  # @author @barjo
  class Resource
    include PaginationSupport
    include NestedSupport

    # A resource always have an id
    attr_accessor :id

    class << self
      # Set this resource client configuration
      # @param [Configuration] config the api url and client default headers.
      def conf(config)
        @conf ||= config
      end

      # Set the resource path, default is the class name in lower case.
      # @param [String] path the resource path
      def path(path = nil)
        @path ||= path || low_name
      end

      # @param [*String] names the resource field names
      def fields(*names)
        @fields ||= field_accessor(names) && names
      end

      # GET /<path>.json
      # @param [Hash] params query parameters
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      # @return [Enumerator] enumerate the resources available at this path.
      def index(params = {})
        get(params)
      end

      # POST /<resource_path>.json
      # Create a new resource. The resource will be indexed by it's name.
      # @param [Object] content the resource/attributes to be created.
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      # @return the created resource
      def create(content)
        data = { low_name => content }
        post(data)
      end

      # GET /<resource_path>/{id}
      # @param [String, Integer] id the resource id
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      # @return the resource available at that path
      def show(id, params = {})
        get(params, id)
      end

      # GET /<path>/{id}/<name>
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      def get(params = {}, id = nil, name = nil, resource_class = nil)
        resp = @conf.requestor.get(@path, params, id, name)
        (resource_class || self).from_response resp
      end

      # POST /<path>/{id}/<name>
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      # @raise [ArgumentError] if data cannot be serialized as a json string ( .to_json )
      def post(data, id = nil, name = nil, resource_class = nil)
        verify_json(data)
        resp = @conf.requestor.post(data, @path, id, name)
        (resource_class || self).from_response resp
      end

      # Will query PUT /<path>/{id}
      # @param [String, Integer] id the id of the resource that needs to be updated
      # @param [Object] content the updated attributes/fields/resource
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      # @return the updated resource
      def update(id, content)
        data = { low_name => content }
        put(data, id)
      end

      # PUT /<path>/{id}/<name>
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      # @raise [ArgumentError] if data cannot be serialized as a json string ( .to_json )
      def put(data, id = nil, name = nil, resource_class = nil)
        verify_json(data)
        resp = @conf.requestor.put(data, @path, id, name)
        (resource_class || self).from_response resp
      end

      # delete /<path>/{id}.json
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      def delete(id = nil, name = nil, resource_class = nil)
        resp = @conf.requestor.delete(@path, id, name)
        (resource_class || self).from_response resp
      end

      def low_name
        @low_name ||= name.demodulize.downcase
      end

      # Create a resouce instance from an Hash.
      # @param [Hash] hash the resource fields with their values
      # @param [Boolean] track_changes if true all fields will be marked has changed
      # @return [Resource] the newly created resource
      def build(hash, track_changes = true)
        resource = fields.each_with_object(new) do |field, r|
          r.send("#{field}=", hash[field.to_s] || hash[field.to_sym])
        end
        resource.clear_changes! unless track_changes
        resource
      end

      # @return [Response] the last response that has been received for that resource
      def last_response
        Thread.current[:_tclr]
      end

      protected

      # Create a resource instance from a {Response}.
      # If the response contains an Array of resource hash, an Enumerator will be return.
      # @param [Response] response obtained from making a request.
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      # @return [Resource, Enumerator, nil] the resources created from the given response.
      def from_response(response)
        Thread.current[:_tclr] = response
        body = response.parse_body
        return build(body, false) if body.is_a? Hash
        return Enumerator.new(body.size) do |yielder|
          inner = body.each
          loop { yielder << build(inner.next, false) }
        end if body.is_a? Array
        body # no content
      end

      private

      def verify_json(data)
        raise ArgumentError, 'data must respond to .to_json' unless data.respond_to? :to_json
      end

      def field_accessor(names)
        names.each do |name|
          class_eval <<-RUBY
            def #{name}; @#{name} end

            def #{name}=(#{name})
              @#{name}= #{name}
              @changes << :#{name} # keep track of fields that has been modified
            end
            RUBY
        end
      end
    end

    # the fields that has beem modified, and will be save on {save!}
    attr_reader :changes

    def initialize(*_args)
      @changes = Set.new # store the fields change here
    end

    # Save the resource fields that has changed, or create it, if it's a new one!
    #    Create the a new resource if id is not set or update the corresonding resource.
    #    Create is done by calling POST on the resource path
    #    Update is done by calling PUT on the resource id ( path/id )
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    # @return [Resource] the updated resource
    def save!
      data = @changes.to_a.each_with_object({}) { |field, h| h[field] = send(field) }
      saved = id.present? ? self.class.update(id, data) : self.class.create(data)
      clone_fields(saved)
      clear_changes!
      self
    end

    # Destroy this resource. It will call delete on this resource id.
    # DELETE /path/id
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    # @raise [ResourceError] if this resource does not have an id.
    # @return the deleted resource
    def destroy!
      raise ResourceError, 'Cannot delete resource if @id not present' if id.blank?
      self.class.delete(id)
      self
    end

    # Load/Reload this resource from the server.
    # It will reset all fields that has been retrieved through the request.
    # It will do a GET request on the resource id (:show)
    # @param [Hash] params optional query parameters
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    # @raise [ResourceError] if this resource does not have an id.
    # @return self with updated fields.
    def load!(params = {})
      raise ResourceError, 'Cannot delete resource if @id not present' if id.blank?
      # get the values from the persistence layer
      reloaded = self.class.show(@id, params)
      clone_fields(reloaded)
      clear_changes!
      reloaded
    end

    # Mark all fields has not changed. This mean that calling save! will not modify this resource
    # until a field attribute has been changed.
    def clear_changes!
      @changes.clear
    end

    # see http://edgeguides.rubyonrails.org/active_support_core_extensions.html#json-support
    # @param [Hash] options for the hash transformation
    # @option [Array] only limit the hash content to those fields
    # @return [Hash] a json ready representation of this resource
    def as_json(options = {})
      self.class.fields.each_with_object({}) do |field, h|
        h[field] = send(field)
      end.as_json(options)
    end

    alias to_h as_json

    private

    def clone_fields(resource)
      self.class.fields.each { |f| send("#{f}=", resource.send(f)) }
    end
  end
end
