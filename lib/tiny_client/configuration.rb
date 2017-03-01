# frozen_string_literal: true
module TinyClient
  class Configuration
    include Singleton
    attr_reader :url, :headers

    private

    def initialize
      @url = 'http://localhost:3000/api/1.0'
      @headers = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'User-Agent' => 'TINYpulse client 1.0'
      }
    end
  end
end
