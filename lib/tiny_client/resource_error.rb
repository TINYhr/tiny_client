require 'tiny_client/base_error'

module TinyClient
  # Raised when an trying to {Resource#load!} or {Resource#destroy!} a resource that does not have
  # an id.
  class ResourceError < BaseError; end
end
