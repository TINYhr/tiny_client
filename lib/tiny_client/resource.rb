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
    include Nested

    # A resource always have an id
    attr_accessor :id

    class << self
      attr_reader :path, :fields

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

      # Similar to {index} but return all resources available at this path. It use limit and offset
      # params to retrieved all resources. ( buffered by the limit size)
      def index_all(params = {})
        get_all(params)
      end

      # Similar to {index_all}, the return enumerator will yield on the buffered ( limit )
      # rather than each element.
      def index_in_batches(params = {})
        get_in_batches(params)
      end

      def get_all(params = {}, id = nil, name = nil, resource_class = nil)
        Enumerator.new do |y|
          count = limit = params.fetch(:limit, @conf.limit || 100)
          offset = params.fetch(:offset, 0)
          while limit == count
            inner = get(params.merge(limit: limit, offset: offset), id, name, resource_class)
            loop { y << inner.next }
            offset += limit
            count = inner.count
          end
        end
      end

      def get_in_batches(params = {}, id = nil, name = nil, resource_class = nil)
        Enumerator.new do |y|
          count = limit = params.fetch(:limit, @conf.limit || 100)
          offset = params.fetch(:offset, 0)
          while limit == count
            inner = get(params.merge(limit: limit, offset: offset), id, name, resource_class)
            loop { y << inner }
            offset += limit
            count = inner.count
          end
        end
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
        url = UrlBuilder.url(@conf.url).path(@path).path(id).path(name).query(params).build!
        resp = CurbRequestor.perform_get(url, { 'Accept' => 'application/json',
                                                'Content-Type' => 'application/x-www-form-urlencoded'
                                              }.merge!(@conf.headers))
        (resource_class || self).from_response resp
      end

      # POST /<path>/{id}/<name>
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      # @raise [ArgumentError] if data cannot be serialized as a json string ( .to_json )
      def post(data, id = nil, name = nil, resource_class = nil)
        verify_json(data)
        url = UrlBuilder.url(@conf.url).path(@path).path(id).path(name).build!
        resp = CurbRequestor.perform_post(url, { 'Accept' => 'application/json',
                                                 'Content-Type' => 'application/json'
                                               }.merge!(@conf.headers), data.to_json)
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
        url = UrlBuilder.url(@conf.url).path(@path).path(id).path(name).build!
        resp = CurbRequestor.perform_put(url, { 'Accept' => 'application/json',
                                                'Content-Type' => 'application/json'
                                              }.merge!(@conf.headers), data.to_json)
        (resource_class || self).from_response resp
      end

      # delete /<path>/{id}.json
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      def delete(id = nil, name = nil, resource_class = nil)
        url = UrlBuilder.url(@conf.url).path(@path).path(id).path(name).build!
        resp = CurbRequestor.perform_delete(url, { 'Accept' => 'application/json',
                                                   'Content-Type' => 'application/x-www-form-urlencoded'
                                              }.merge!(@conf.headers))
        (resource_class || self).from_response resp
      end

      def low_name
        @low_name ||= name.demodulize.downcase
      end

      # Create a resouce instance from an Hash.
      # @param [Hash] hash the resource fields with their values
      # @param [Boolean] track_changes if true all fields will be marked has changed
      # @return [Resource] the newly created resource
      def from_hash(hash, track_changes = true)
        resource = fields.each_with_object(new) { |field, r| r.send("#{field}=", hash[field.to_s]) }
        resource.clear_changes! unless track_changes
        resource
      end

      protected

      # Create a resource instance from a {Response}.
      # If the response contains an Array of resource hash, an Enumerator will be return.
      # @param [Response] response obtained from making a request.
      # @return [Resource, Enumerator, nil] the resources created from the given response.
      def from_response(response)
        body = response.parse_body
        return from_hash(body, false) if body.is_a? Hash
        return Enumerator.new(body.size) do |yielder|
          inner = body.each
          loop { yielder << from_hash(inner.next, false) }
        end if body.is_a? Array
        body
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
      saved = if id.present?
                self.class.update(id, as_json(only: @changes.to_a))
              else
                self.class.create(as_json(only: @changes.to_a))
              end
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
