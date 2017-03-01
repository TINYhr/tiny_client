require 'curb'

module TinyClient

  # Allows to perform a request with Curb and wrapped the response.
  # Curb client are attached to a current thread Fiber. ( One curb per Fiber. )
  module CurbRequestor
    # make a request, return a response
    def perform_request(url, headers, put_data: nil)
      curl = current_curb do |c|
        c.url = url
        c.headers = headers
        c.put_data = put_data if put_data.present?
        yield c if block_given?
      end
      curl.perform
      Response.new(curl)
    end

    private

    def current_curb
      # TODO, not sure if we should use Fiber local variable or Thread local variable here.
      curl = Thread.current[:tc_curb]
      unless curl
        curl = Curl::Easy.new
        Thread.current[:tc_curb] = curl
      end
      yield curl
      curl
    end
  end
end
