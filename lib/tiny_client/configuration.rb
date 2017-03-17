module TinyClient
  # Provides the default client configuration
  # Subclass and override {#initialize} to implement a client confiuration.
  # @abstract
  # @attr_reader [String] url the api root url (i.e: http://localhost/api/1.0)
  # @attr_reader [Hash] headers default headers you want to pass along every request
  # @attr_reader [Integer] limit default limit used as a query param
  class Configuration
    include Singleton
    attr_reader :url, :headers, :limit

    # You need to initialize the api {#url}, default {#headers}, and default limit.
    def initialize
      raise NotImplementedError
    end

    # @return [Integer] request connection timeout in seconds
    def connect_timeout
      @connect_timeout ||= 30
    end
  end
end
