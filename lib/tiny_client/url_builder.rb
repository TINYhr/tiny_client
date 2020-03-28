require 'active_support/core_ext/hash'

module TinyClient
  # Convenient class used to build a request URL.
  class UrlBuilder
    SEPARATOR = '/'.freeze

    def self.url(url)
      new(url)
    end

    def path(*paths)
      paths.each do |path|
        new_path = fix_path(path)
        @path << new_path if new_path.present?
      end
      self
    end

    def query(params = {})
      @query.merge!(params) unless params.empty?
      self
    end

    # @return [String] url with all paths and query params
    def build
      url = "#{[@url, @path].join(SEPARATOR)}.json"
      url = "#{url}?#{@query.to_query}" unless @query.empty?
      url
    end

    # @deprecated Please use {#build} instead
    def build!
      ActiveSupport::Deprecation.warn('`build!` is deprecated. Please use `build` instead')
      build
    end

    private

    def initialize(url)
      @url = parse_url(url)
      @path = []
      @query = {}
    end

    def parse_url(url)
      if url.blank? || url == SEPARATOR
        ''
      else
        url = url[0..-2] if url.end_with?(SEPARATOR)
        url
      end
    end

    def fix_path(path)
      case path
      when String
        path = path.gsub(/\.json$/, '')
        path = path[1..-1] if path.start_with?('/')
        path = path[0..-2] if path.end_with?('/')
        path
      else
        path
      end
    end
  end
end
