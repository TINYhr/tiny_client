module TinyClient
  # Remote Http client which delegates to the {CurbRequestor}.
  class RemoteClient
    def initialize(config)
      @config = config
    end

    #    GET /<path>/<id>/<name>?<params>
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    # @return [Response]
    def get(path, params, id, name)
      url = @config.url_for(path, id, name, params)
      CurbRequestor.perform_get(url, {
        'Accept' => 'application/json',
        'Content-Type' => 'application/x-www-form-urlencoded'
      }.merge!(@config.headers), @config.connect_timeout, @config.verbose)
    end

    #    GET /<path>/<id>/<name>?<params>
    # @param [Hash] data
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    # @return [Response]
    def body_data_get(path, params, id, name, data)
      url = @config.url_for(path, id, name, params)
      verify_json(data)
      CurbRequestor.perform_body_get(url, {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      }.merge!(@config.headers), data.to_json, @config.connect_timeout, @config.verbose)
    end

    #    POST /<path>/<id>/<name>
    # @param [Hash] data
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    # @return [Response]
    def post(data, path, id, name)
      url = @config.url_for(path, id, name)
      verify_json(data)
      CurbRequestor.perform_post(url, {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      }.merge!(@config.headers), data.to_json, @config.connect_timeout, @config.verbose)
    end

    #    PUT /<path>/<id>/<name>
    # @param [Hash] data the resource data
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    # @return [Response]
    def put(data, path, id, name)
      url = @config.url_for(path, id, name)
      verify_json(data)
      CurbRequestor.perform_put(url, {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      }.merge!(@config.headers), data.to_json, @config.connect_timeout, @config.verbose)
    end

    #    DELETE /<path>/<id>.json
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    # @return [Response]
    def delete(path, id, name)
      url = @config.url_for(path, id, name)
      CurbRequestor.perform_delete(url, {
        'Accept' => 'application/json',
        'Content-Type' => 'application/x-www-form-urlencoded'
      }.merge!(@config.headers), @config.connect_timeout, @config.verbose)
    end

    private

    def verify_json(data)
      raise ArgumentError, 'data must respond to .to_json' unless data.respond_to? :to_json
    end
  end
end
