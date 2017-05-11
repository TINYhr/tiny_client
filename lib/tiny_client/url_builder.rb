require 'active_support/core_ext/hash'

module TinyClient
  # Convenient class used to build a request URL.
  class UrlBuilder
    SEPARATOR = '/'.freeze
    attr_writer :query

    def self.url(url)
      new(url)
    end

    def path(path)
      @path << fix_path(path) unless path.blank?
      self
    end

    def query(params = {})
      @query.merge!(params) unless params.empty?
      self
    end

    def build!
      query_s = "?#{@query.to_query}" unless @query.empty?
      "#{@path.join(SEPARATOR)}.json#{query_s}"
    end

    private

    def initialize(url)
      @path = [url]
      @query = {}
    end

    def fix_path(path)
      if path.respond_to?(:gsub)
        path.gsub(/\.json$/, '')
      else
        path
      end
    end
  end
end
