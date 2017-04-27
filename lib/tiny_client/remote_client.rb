module TinyClient
  # Remote Http client which delegates to the {CurbRequestor}.
  class RemoteClient
    def initialize(config)
      @config = config
    end

    # GET /<path>/{id}/<name>?<params>
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    # @return [Response]
    def get(path, params, id, name)
      url = build_url(path, id, name).query(params).build!
      CurbRequestor.perform_get(url, {
        'Accept' => 'application/json',
        'Content-Type' => 'application/x-www-form-urlencoded'
      }.merge!(@config.headers), @config.connect_timeout, @config.verbose)
    end

    # POST /<path>/{id}/<name>
    # @data [Hash]
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    # @return [Response]
    def post(data, path, id, name)
      url = build_url(path, id, name).build!
      CurbRequestor.perform_post(url, {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      }.merge!(@config.headers), data.to_json, @config.connect_timeout, @config.verbose)
    end

    # PUT /<path>/{id}/<name>
    # @data [Hash]
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    # @return [Response]
    def put(data, path, id, name)
      url = build_url(path, id, name).build!
      CurbRequestor.perform_put(url, {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      }.merge!(@config.headers), data.to_json, @config.connect_timeout, @config.verbose)
    end

    # DELETE /<path>/{id}.json
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    # @return [Response]
    def delete(path, id, name)
      url = build_url(path, id, name).build!
      CurbRequestor.perform_delete(url, {
        'Accept' => 'application/json',
        'Content-Type' => 'application/x-www-form-urlencoded'
      }.merge!(@config.headers), @config.connect_timeout, @config.verbose)
    end

    private

    def build_url(path, id, name)
      UrlBuilder.url(@config.url).path(path).path(id).path(name)
    end
  end
end
