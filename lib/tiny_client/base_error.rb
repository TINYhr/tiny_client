module TinyClient
  # A base class for all errors of tiny client
  # This class provides an error which we can rescue and catch all tiny client
  # errors with
  class BaseError < StandardError; end
end
