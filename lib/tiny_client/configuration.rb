# frozen_string_literal: true
module TinyClient
  class Configuration
    include Singleton
    attr_reader :url, :headers

    private

    def initialize
      @url = 'http://localhost:3000/api/1.0'
      @headers = {
        'Authorization' => 'Token eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwcC50aW55cHVsc2UuY29tIiwiaWF0IjoxNDg3NjUxNzY5LCJqdGkiOiJhNDA1YjIxMTdmNGQ3ODc0ODAxM2E0YWI2ZTU4YmMzYiIsInN1YiI6IlRJTllwdWxzZSBBUEkgYWNjZXNzIFRva2VuIiwiYXVkIjoiVElOWXB1bHNlIn0.hstm7u6cIvSzebRC6RkIDIUjPHQPKMHSKMggibtUF6s',
        'Content-Type' => 'application/json',
        'User-Agent' => 'TINYpulse client 1.0'
      }
    end
  end
end
