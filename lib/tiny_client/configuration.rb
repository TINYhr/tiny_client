module TinyClient
  # Provides the default client configuration
  # Subclass and override {#initialize} to implement a client confiuration.
  # @abstract
  # @attr_reader [String] url the api root url (i.e: http://localhost/api/1.0)
  # @attr_reader [Integer] limit default limit used as a query param
  class Configuration
    include Singleton

    attr_reader :url, :limit

    # You need to initialize the api {#url}, default {#headers}, and default limit.
    def initialize
      raise NotImplementedError
    end

    # @return [Integer] request connection timeout in seconds
    def connect_timeout
      @connect_timeout ||= 30
    end

    # @return [Hash] headers default headers you want to pass along every request
    def headers
      @headers ||= {}
    end

    # @return [Boolean] true if curl verbose option is set
    def verbose
      @verbose ||= false
    end

    # @return [String] url using `TinyClient::UrlBuilder` to build url
    def url_for(*args)
      query = args.extract_options!
      url_builder.path(*args).query(query).build
    end

    # @return [TinyClient::UrlBuilder] url_builder
    def url_builder
      TinyClient::UrlBuilder.url(url)
    end

    # @return [TinyClient::RemoteClient] requestor
    def requestor
      @requestor ||= TinyClient::RemoteClient.new(self)
    end
  end
end
