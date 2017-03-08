require 'json/ext'

module TinyClient
  #
  # Wrap the curl response.
  #
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
    def parse_body(object_class = OpenStruct)
      params = { object_class: object_class } if object_class.present?
      JSON.parse(body_str, params) if body_str.present?
    end

    def success?
      (200..299).cover?(@code)
    end

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
  end
end
