require 'curb'

module TinyClient
  # Allows to perform a request with Curb and wrapped the response.
  # Curb client are attached to a current thread Fiber. ( One curb per Fiber. )
  module CurbRequestor
    def perform_get(url, headers)
      Response.new(Curl.get(url) { |c| c.headers = headers })
    end

    def perform_put(url, headers, content)
      Response.new(Curl.put(url, content) { |c| c.headers = headers })
    end

    def perform_post(url, headers, content)
      Response.new(Curl.post(url, content) { |c| c.headers = headers })
    end
  end
end
