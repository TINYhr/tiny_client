require 'tiny_client/base_error'

module TinyClient
  # Raised when an Curb error occured during the request.
  # We usually wrap Curl::Err::ConnectionFailedError in this error
  class RequestError < BaseError; end
end
