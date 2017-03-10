module TinyClient
  # Raised when an trying to {Resource#load!} or {Resource#destroy!} a resource that does not have
  # an id.
  class ResourceError < StandardError; end
end
