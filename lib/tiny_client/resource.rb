require 'set'

module TinyClient
  # Extend to create a simple client for a given resource.
  class Resource
    class << self
      include CurbRequestor

      def conf(config)
        @conf ||= config
      end

      def path(path = nil)
        @path ||= path || name.demodulize.downcase
      end

      def fields(*names)
        unless @fields.present?
          attr_reader(*names)
          @fields = names
        end
        @fields
      end

      def nested(*clazz)
        @nested ||= clazz
      end

      # GET /<resource_path>.json
      def index(params = {})
        get(nil, nil, params, self)
      end

      # POST /<resource_path>.json
      def create(content)
        post(nil, nil, content, self)
      end

      # DELETE /<resource_path>/{id}
      def delete(_id)
        raise NotImplementedError
      end

      # GET /<resource_path>/{id}
      def show(id, params = {})
        get(id, nil, params, self)
      end

      # GET /<resource_path/{id}/<name>
      def get(id, name, params, resource_class)
        url = UrlBuilder.url(@conf.url).path(@path).path(id).path(name).query(params).build!
        resp = perform_get(url, { 'Accept' => 'application/json',
                                  'Content-Type' => 'application/x-www-form-urlencoded'
                                }.merge!(@conf.headers))
        raise ResponseError.new(resp) if resp.error?
        resp.to_object(resource_class)
      end

      # POST /<resource_path>/{id}/<name>
      def post(id, name, content, resource_class)
        url = UrlBuilder.url(@conf.url).path(@path).path(id).path(name).build!
        resp = perform_post(url, { 'Accept' => 'application/json',
                                   'Content-Type' => 'application/json'
                                }.merge!(@conf.headers), content.to_json)
        raise ResponseError.new(resp) if resp.error?
        resp.to_object(resource_class)
      end

      # PUT /<resource_path>/{id}
      def update(id, content)
        url = UrlBuilder.url(@conf.url).path(@path).path(id).build!
        resp = perform_put(url, { 'Accept' => 'application/json',
                                  'Content-Type' => 'application/json'
                                }.merge!(@conf.headers), content.to_json)
        raise ResponseError.new(resp) if resp.error?
        resp.to_object(self)
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
        name = clazz.name.demodulize.downcase

        send(:define_singleton_method, "#{name}s") do |params = {}|
          get_nested(clazz, params)
        end

        send(:define_singleton_method, "add_#{name}") do |resource|
          create_nested(resource)
        end
      end

      @changes = Set.new
    end

    # Save this resource attributes that has changed, or create it, if it's a new one!
    # It will do a PUT request (:update)
    def save!
      # resource object start is identified by it's class name
      data = { self.class.name.demodulize.downcase => changed_attributes }
      saved = if id.present?
                self.class.update(id, data)
              else
                self.class.create(data)
              end
      clone_fields(saved)
      @changes.clear
      self
    end

    # Load this resources attributes from the server.
    # It will do a GET request on the resource id (:show)
    def load!(params = {})
      # get the values from the persistence layer
      reloaded = self.class.show(@id, params)
      clone_fields(reloaded)
      @changes.clear
      reloaded
    end

    def get_nested(resource_class, params = {})
      self.class.get(@id, resource_class.path, params, resource_class)
    end

    def create_nested(resource)
      raise ArgumentError, 'resource must be an instance of TinyClient::Resource' unless resource.is_a? Resource
      self.class.post(@id, resource.class.path, resource, resource.class)
    end

    def to_h
      self.class.fields.each_with_object({}) do |name, h|
        value = instance_variable_get("@#{name}")
        h[name] = value if value.present?
      end
    end

    def to_json
      to_h.to_json
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
