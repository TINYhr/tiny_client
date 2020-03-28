require 'active_support/core_ext/hash'

module TinyClient
  # Convenient class used to build a request URL.
  class UrlBuilder
    SEPARATOR = '/'.freeze

    def self.url(url)
      new(url)
    end

    def path(*paths)
      paths.each { |path| @path << fix_path(path) if path.present? && path != '/' }
      self
    end

    def query(params = {})
      @query.merge!(params) unless params.empty?
      self
    end

    def build!
      url = "#{[@url, @path].join(SEPARATOR)}.json"
      url.gsub!('//', '/')
      url = "#{url}?#{@query.to_query}" unless @query.empty?
      url
    end

    private

    def initialize(url)
      @url = url
      @path = []
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
