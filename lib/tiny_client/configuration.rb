# frozen_string_literal: true
module TinyClient
  class Configuration
    include Singleton
    attr_reader :url, :headers

    private

    def initialize
      @url = ''
      @headers = {
        'User-Agent' => 'TINYpulse client 1.0'
      }
    end
  end
end
