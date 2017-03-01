require 'tiny_client'
require_relative 'config'

module Dummy
  class Post < TinyClient::Resource
    conf Config.instance

    path 'posts'
    fields :id, :name, :content
  end
end
