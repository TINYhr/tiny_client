module TinyClient
  # Raised when an HTTP error occured during the request. See {Response#error?}
  class ResponseError < StandardError
    attr_reader :response

    def initialize(response)
      @response = response
      @message = "Error #{response.status} occured when calling #{response.url}"
    end
  end
end
