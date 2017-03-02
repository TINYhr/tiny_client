require 'curb'

module TinyClient
  # Allows to perform request with Curb and wrapped the response.
  # Curb client are attached to a current thread Fiber. ( One curb per Fiber. )
  module CurbRequestor
    # Perform a get request with Curl
    # @param url [String] the full url
    # @param headers [Hash] the request headers
    # @return [TinyClient::Response] the request response
    def perform_get(url, headers)
      Response.new(Curl.get(url) { |c| c.headers = headers })
    end

    # Perform a put request with Curl
    # @param url [String] the full url
    # @param headers [Hash] the request headers
    # @param content [String] the request body content
    # @return [TinyClient::Response] the request response
    def perform_put(url, headers, content)
      Response.new(Curl.put(url, content) { |c| c.headers = headers })
    end

    # Perform a post request with Curl
    # @param url [String] the full url
    # @param headers [Hash] the request headers
    # @param content [String] the request body content
    # @return [TinyClient::Response] the request response
    def perform_post(url, headers, content)
      Response.new(Curl.post(url, content) { |c| c.headers = headers })
    end
  end
end
