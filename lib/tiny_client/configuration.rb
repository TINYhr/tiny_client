module TinyClient
  # Provides the default client configuration
  # Subclass and override {#initialize} to implement a client confiuration.
  # @abstract
  # @attr_reader [String] url the api root url (i.e: http://localhost/api/1.0)
  # @attr_reader [Hash] headers default headers you want to pass along every request
  class Configuration
    include Singleton
    attr_reader :url, :headers

    # You need to initialize the api {#url} and default {#headers}.
    def initialize; raise NotImplementedError end
  end
end
