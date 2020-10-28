require 'tiny_client/base_error'

module TinyClient
  # Raised when an HTTP error occured during the request. See {Response#error?}
  class ResponseError < BaseError
    attr_reader :response

    def initialize(response)
      @response = response
      super("Error #{response.status} occured when calling #{response.url}")
    end

    def to_hash
      response.to_hash
    end
  end
end
