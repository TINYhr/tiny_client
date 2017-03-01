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

      # GET /<resource_path>
      def index(params = {}, resource_class: nil)
        # get on the resource path (i.e index)
        get(nil, nil, params, resource_class: resource_class)
      end

      # POST /<resource_path>
      def create(_params)
        raise NotImplementedError
      end

      # DELETE /<resource_path>/{id}
      def delete(_id)
        raise NotImplementedError
      end

      # GET /<resource_path>/{id}
      def show(id, params = {})
        # GET on the resource id, i.e path/id
        get(id, nil, params, resource_class: self)
      end

      # GET /<resource_path/{id}/<name>
      def get(id, name, params = {}, resource_class: nil)
        url = UrlBuilder.url(@conf.url).path(@path).path(id).path(name).query(params).build!
        resp = perform_request(url, @conf.headers)
        raise ResponseError.new(resp) if resp.error?
        resp.to_object(resource_class || self)
      end

      # PUT /<resource_path>/{id}
      def update(id, params)
        url = UrlBuilder.url(@conf.url).path(@path).path(id).build!
        resp = perform_request(url, @conf.headers, put_data: params.to_json)
        raise ResponseError.new(resp) if resp.error?
        resp.to_object(resource_class || self)
      end
    end

    def initialize(*_args)
      self.class.fields.each do |name|
        send(:define_singleton_method, "#{name}=") do |value|
          self.[]=(name, value)
          @changes << name
        end
      end
      @changes = Set.new
    end

    # Save this resource attributes that has changed!
    # It will do a PUT request (:update)
    def update!
      # resource object start is identified by it's class name
      data = { self.class.name.demodulize.downcase => changed_attributes }
      saved = self.class.update(@id, data)
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

    def get(member, params = {}, options = {})
      self.class.get(@id, member, params, options)
    end

    def to_h
      self.class.fields.each_with_object({}) { |name, h| h[name] = instance_variable_get("@#{name}") }
    end

    def path
      self.class.path
    end

    def fields
      self.class.fields
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
      to_h.select { |k, _v| @changes.include?(k) }
    end
  end
end
