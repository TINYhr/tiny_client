require 'set'

module TinyClient
  # @markup markdown
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
      # @param [String] the resource path
      def path(path = nil)
        @path ||= path || low_name
      end

      # @param [*String] names the resource field names
      def fields(*names)
        @fields ||= field_accessor(names) && names
      end

      # GET /<path>.json
      # @param [Hash] optional query parameters
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      # @return [Enumerator] enumerate the resources available at this path.
      def index(params = {})
        get(params)
      end

      # Similar to {#index} but return all resources available at this path. It use limit and offset
      # params to retrieved all resources. ( buffered by the limit size)
      def index_all(params = {})
        get_all(params)
      end

      # Similar to {#index_all}, the return enumerator will yield on the buffered ( limit )
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
        data = { low_name => content.to_h }
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
      # @param [Object] the updated attributes/fields/resource
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      # @return the updated resource
      def update(id, content)
        data = { low_name => content.to_h }
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

      def from_response(response)
        body = response.parse_body(nil)
        return from_hash(body) if body.is_a? Hash
        return Enumerator.new(body.size) do |yielder|
          inner = body.each
          loop { yielder << from_hash(inner.next) }
        end if body.is_a? Array
        body
      end

      def from_hash(h)
        fields.each_with_object(new) { |f, r| r.send("#{f}=", h[f.to_s]) }
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
                self.class.update(id, changed_attributes)
              else
                self.class.create(changed_attributes)
              end
      clone_fields(saved)
      @changes.clear
      self
    end

    # Destroy this resource. It will call delete on this resource id.
    # DELETE /path/id
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    # @raise ResourceError if this resource does not have an id.
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
    # @return self with updated fields.
    def load!(params = {})
      # get the values from the persistence layer
      reloaded = self.class.show(@id, params)
      clone_fields(reloaded)
      @changes.clear
      reloaded
    end

    # @return [Hash] an hash representation of this resource fields.
    def to_h
      self.class.fields.each_with_object({}) do |name, h|
        value = send(name)
        h[name] = value if value.present?
      end
    end

    # @return [String] a json representation of this resource
    def to_json(prefixed = true)
      if prefixed
        { self.class.low_name => to_h }.to_json
      else
        to_h.to_json
      end
    end

    private

    def clone_fields(resource)
      self.class.fields.each { |f| send("#{f}=", resource.send(f)) }
    end

    def changed_attributes
      @changes.each_with_object({}) { |k, h| h[k] = send(k) }
    end
  end
end
