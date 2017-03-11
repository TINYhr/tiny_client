require 'tiny_client'
require_relative 'config'

module Dummy
  class Author < TinyClient::Resource
    conf Config.instance
    nested Post
    path 'authors'
    fields :id, :name, :info

    def birthday
      info['birthday']
    end
  end
end
