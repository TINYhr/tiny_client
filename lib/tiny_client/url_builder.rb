require 'active_support/core_ext/hash'

module TinyClient
  class UrlBuilder
    SEPARATOR = '/'.freeze
    attr_writer :query

    def self.url(url)
      new(url)
    end

    def path(path)
      @path << path unless path.blank?
      self
    end

    def query(params = {})
      @query.merge!(params) unless params.empty?
      self
    end

    def build!
      query_s = "?#{@query.to_query}" unless @query.empty?
      "#{@path.join(SEPARATOR)}#{query_s}.json"
    end

    private

    def initialize(url)
      @path = [url]
      @query = {}
    end
  end
end
