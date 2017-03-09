module Dummy
  # Dummy confiuration
  class Config < TinyClient::Configuration
    attr_writer :url, :headers

    def initialize
      @url = 'http://localhost:3000/api/1.0'
      @headers = {
        'Authorization' => 'Token toto',
        'User-Agent' => 'TINYpulse client 1.0',
        'Accept-Encoding' => 'gzip'
      }
    end
  end
end
