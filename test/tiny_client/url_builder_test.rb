require 'test_helper'

describe TinyClient::UrlBuilder do
  describe '#path' do
    it 'supports multiple paths in call' do
      url = TinyClient::UrlBuilder.url('/')
            .path('organizations', 1)
            .build
      _(url).must_equal '/organizations/1.json'

      url = TinyClient::UrlBuilder.url('/')
            .path('organizations', 1, 'permissions/1')
            .build
      _(url).must_equal '/organizations/1/permissions/1.json'
    end

    it 'ignores path that is blank or /' do
      url = TinyClient::UrlBuilder.url('/')
            .path('permissions/1.json')
            .path('')
            .path(nil)
            .path('/')
            .build
      _(url).must_equal '/permissions/1.json'
    end

    it 'removes ".json" suffix in path' do
      url = TinyClient::UrlBuilder.url('/organizations')
            .path(1)
            .path('permissions/1.json')
            .build
      _(url).must_equal '/organizations/1/permissions/1.json'

      url = TinyClient::UrlBuilder.url('/organizations')
            .path(1)
            .path('roles/1.json')
            .path('permissions/1.json')
            .build
      _(url).must_equal '/organizations/1/roles/1/permissions/1.json'
    end
  end
end
