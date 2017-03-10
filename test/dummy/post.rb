require 'tiny_client'
require_relative 'config'

module Dummy
  class Post < TinyClient::Resource
    conf Config.instance

    path 'posts'
    fields :id, :name, :content

    def initialize(name = nil, content = nil)
      super
      self.name = name
      self.content = content
    end
  end
end
