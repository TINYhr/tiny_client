require 'curb'

module TinyClient
  # Allows to perform request with Curb and wrapped the response.
  # Curb client are attached to a current thread Fiber. ( One curb per Fiber. )
  module CurbRequestor
    class << self
      # Perform a get request with Curl
      # @param [String] url the full url
      # @param [Hash] headers  the request headers
      # @param [Integer] connect_timeout timeout if the request connection go over (in second)
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      # @return [TinyClient::Response] the request response
      def perform_get(url, headers, connect_timeout)
        perform(:GET, url, nil, nil, headers: headers, connect_timeout: connect_timeout)
      end

      # Perform a put request with Curl
      # @param [String] url the full url
      # @param [Hash] headers  the request headers
      # @param [String] content the request body content
      # @param [Integer] connect_timeout timeout if the request connection go over (in second)
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      # @return [TinyClient::Response] the request response
      def perform_put(url, headers, content, connect_timeout)
        perform(:PUT, url, nil, content, headers: headers, connect_timeout: connect_timeout)
      end

      # Perform a post request with Curl
      # @param [String] url the full url
      # @param [Hash] headers  the request headers
      # @param [String] content the request body content
      # @param [Integer] connect_timeout timeout if the request connection go over (in second)
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      # @return [TinyClient::Response] the request response
      def perform_post(url, headers, content, connect_timeout)
        perform(:POST, url, content, nil, headers: headers, connect_timeout: connect_timeout)
      end

      # Perform a delete request with Curl
      # @param [String] url the full url
      # @param [Hash] headers  the request headers
      # @param [Integer] connect_timeout timeout if the request connection go over (in second)
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      # @return [TinyClient::Response] the request response
      def perform_delete(url, headers, connect_timeout)
        perform(:DELETE, url, nil, nil, headers: headers, connect_timeout: connect_timeout)
      end

      # Perform a head request with Curl
      # @param [String] url the full url
      # @param [Hash] headers  the request headers
      # @param [Integer] connect_timeout timeout if the request connection go over (in second)
      # @raise [ResponseError] if the server respond with an error status (i.e 404, 500..)
      # @return [TinyClient::Response] the request response
      def perform_head(url, headers, connect_timeout)
        perform(:HEAD, url, nil, nil, headers: headers, connect_timeout: connect_timeout)
      end

      private

      def perform(verb, url, post_body, put_data, options = {})
        response = Response.new(Curl.http(verb, url, post_body, put_data) do |c|
          c.headers = options[:headers]
          c.connect_timeout = options[:connect_timeout]
        end)
        raise ResponseError, response if response.error?
        response
      end
    end
  end
end
