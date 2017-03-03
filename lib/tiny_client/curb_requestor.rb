require 'curb'

module TinyClient
  # Allows to perform request with Curb and wrapped the response.
  # Curb client are attached to a current thread Fiber. ( One curb per Fiber. )
  module CurbRequestor
    # Perform a get request with Curl
    # @param url [String] the full url
    # @param headers [Hash] the request headers
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    # @return [TinyClient::Response] the request response
    def self.perform_get(url, headers)
      response = Response.new(Curl.get(url) { |c| c.headers = headers })
      raise ResponseError.new(response) if response.error?
      response
    end

    # Perform a put request with Curl
    # @param url [String] the full url
    # @param headers [Hash] the request headers
    # @param content [String] the request body content
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    # @return [TinyClient::Response] the request response
    def self.perform_put(url, headers, content)
      response = Response.new(Curl.put(url, content) { |c| c.headers = headers })
      raise ResponseError.new(response) if response.error?
      response
    end

    # Perform a post request with Curl
    # @param url [String] the full url
    # @param headers [Hash] the request headers
    # @param content [String] the request body content
    # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
    # @return [TinyClient::Response] the request response
    def self.perform_post(url, headers, content)
      response = Response.new(Curl.post(url, content) { |c| c.headers = headers })
      raise ResponseError.new(response) if response.error?
      response
    end
  end
end
