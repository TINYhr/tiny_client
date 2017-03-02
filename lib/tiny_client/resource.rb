require 'set'

module TinyClient
  # @markup markdown
  # This is the core of TinyClient.
  # Subclass {TinyClient::Resource} in order to create an HTTP/JSON tiny client.
  #
  # {file:README.md Getting Started}
  # @author @barjo
  class Resource
    class << self
      include CurbRequestor

      # Set this resource client configuration
      # @param [Configuration] config the api url and client default headers.
      def conf(config)
        @conf ||= config
      end

      # Set the resource path, default is the class name in lower case.
      # @param [String] the resource path
      def path(path = nil)
        @path ||= path || name.demodulize.downcase
      end

      # @param [*String] names the resource field names
      def fields(*names)
        unless @fields.present?
          attr_reader(*names)
          @fields = names
        end
        @fields
      end

      # Set nested resources. Nested resource creation and getters method will be created.
      # If the resource class is called Post, then {add_post} and {posts} methods will be created.
      # @param [Resource] clazz the nested resource class.
      def nested(*clazz)
        @nested ||= clazz
      end

      # GET /<path>.json
      # @param [Hash] optional query parameters
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      # @return the list of resources available at this path.
      def index(params = {})
        get(nil, nil, params, self)
      end

      # POST /<resource_path>.json
      # Create a new resource. The resource will be indexed by it's name.
      # @param [Object] content the resource/attributes to be created.
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      # @return the created resource
      def create(content)
        data = { low_name => content.to_h }
        post(nil, nil, data, self)
      end

      # DELETE /<resource_path>/{id}
      def delete(_id)
        raise NotImplementedError
      end

      # GET /<resource_path>/{id}
      # @param [String, Integer] id the resource id
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      # @return the resource available at that path
      def show(id, params = {})
        get(id, nil, params, self)
      end

      # GET /<path>/{id}/<name>
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      def get(id, name, params, resource_class)
        url = UrlBuilder.url(@conf.url).path(@path).path(id).path(name).query(params).build!
        resp = perform_get(url, { 'Accept' => 'application/json',
                                  'Content-Type' => 'application/x-www-form-urlencoded'
                                }.merge!(@conf.headers))
        raise ResponseError.new(resp) if resp.error?
        resp.to_object(resource_class)
      end

      # POST /<path>/{id}/<name>
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      def post(id, name, data, resource_class)
        url = UrlBuilder.url(@conf.url).path(@path).path(id).path(name).build!
        resp = perform_post(url, { 'Accept' => 'application/json',
                                   'Content-Type' => 'application/json'
                                }.merge!(@conf.headers), data.to_json)
        raise ResponseError.new(resp) if resp.error?
        resp.to_object(resource_class)
      end

      # Will query PUT /<path>/{id}
      # @param [String, Integer] id the id of the resource that needs to be updated
      # @param [Object] the updated attributes/fields/resource
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      # @return the updated resource
      def update(id, content)
        data = { low_name => content.to_h }
        put(id, nil, data, self)
      end

      # PUT /<path>/{id}/<name>
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      def put(id, name, data, resource_class)
        url = UrlBuilder.url(@conf.url).path(@path).path(id).path(name).build!
        resp = perform_put(url, { 'Accept' => 'application/json',
                                  'Content-Type' => 'application/json'
                                }.merge!(@conf.headers), data.to_json)
        raise ResponseError.new(resp) if resp.error?
        resp.to_object(resource_class)
      end

      def low_name
        @low_name ||= name.demodulize.downcase
      end
    end

    def initialize(*_args)
      self.class.fields.each do |name|
        send(:define_singleton_method, "#{name}=") do |value|
          self.[]=(name, value)
          @changes << name
        end
      end

      self.class.nested.each do |clazz|
        send(:define_singleton_method, "#{clazz.low_name}s") { |params = {}| get_nested(clazz, params) }
        send(:define_singleton_method, "add_#{clazz.low_name}") { |resource| create_nested(resource) }
      end

      @changes = Set.new
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

    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    def get_nested(resource_class, params = {})
      self.class.get(@id, resource_class.path, params, resource_class)
    end

    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    def create_nested(resource)
      raise ArgumentError, 'resource must be an instance of TinyClient::Resource' unless resource.is_a? Resource
      data = { resource.class.low_name => resource.to_h }
      self.class.post(@id, resource.class.path, data, resource.class)
    end

    # @return [Hash] an hash representation of this resource fields.
    def to_h
      self.class.fields.each_with_object({}) do |name, h|
        value = instance_variable_get("@#{name}")
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

    protected

    # call by JSON
    def []=(name, value)
      instance_variable_set("@#{name}", value)
    end

    private

    def clone_fields(resource)
      resource.to_h.each { |k, v| self.[]=(k, v) }
    end

    def changed_attributes
      @changes.each_with_object({}) do |k, h|
        h[k] = instance_variable_get("@#{k}")
      end
    end
  end
end
