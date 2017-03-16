require 'active_support/json/decoding'
require 'active_support/gzip'

module TinyClient
  # Wrap the curl request response.
  class Response
    attr_reader :status, :body_str, :header_str, :url, :code

    def initialize(curb)
      @status = curb.status
      @body_str = curb.body_str
      @header_str = curb.header_str
      @code = @status.to_i
      @url = curb.url
    end

    # Convert the response json body into an hash.
    # @return the parsed response body
    def parse_body
      body = gzip? ? gzip_decompress : body_str
      ActiveSupport::JSON.decode(body) if body.present?
    end

    # Parse the X-Total-Count header
    # @return [Integer] the value of the X-Total-Count header, or nil if not present
    def total_count
      count = header_str[/X-Total-Count: ([0-9]+)/, 1]
      count.present? ? count.to_i : nil
    end

    # @return true if this response Content-Encoding is gzip
    def gzip?
      /Content-Encoding: gzip/ =~ header_str
    end

    # @return true if the http request has been successful.
    def success?
      (200..299).cover?(@code)
    end

    # @return true if the HTTP status code of this response correspond to an client or server error.
    def error?
      @code >= 400
    end

    def client_error?
      (400..499).cover?(@code)
    end

    def server_error?
      @code >= 500
    end

    def redirect?
      (300..399).cover?(@code)
    end

    protected

    def gzip_decompress
      ActiveSupport::Gzip.decompress(body_str)
    end
  end
end
