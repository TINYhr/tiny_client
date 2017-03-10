require 'json/ext'
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

    # Convert the response json body into an object.
    # @param [Class] object_class the return class.
    # @return the parsed response body as an instance of `object_class` or nil if empty body.
    def parse_body(object_class = OpenStruct)
      params = { object_class: object_class } if object_class.present?
      body = gzip? ? gzip_decompress : body_str
      JSON.parse(body, params) if body.present?
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
