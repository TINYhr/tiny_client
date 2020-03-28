require 'test_helper'

describe TinyClient::UrlBuilder do
  it 'build url with root url with http' do
    url = TinyClient::UrlBuilder.url('https://example.com/api/v1')
          .path('organizations', 1)
          .build
    _(url).must_equal 'https://example.com/api/v1/organizations/1.json'
  end

  it 'build url with root url end with /' do
    url = TinyClient::UrlBuilder.url('/api/v1/')
          .path('organizations', 1)
          .build
    _(url).must_equal '/api/v1/organizations/1.json'
  end

  it 'build url with blank root url' do
    url = TinyClient::UrlBuilder.url(nil)
          .path('organizations', 1)
          .build
    _(url).must_equal '/organizations/1.json'

    url = TinyClient::UrlBuilder.url('')
          .path('organizations', 1)
          .build
    _(url).must_equal '/organizations/1.json'
  end

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
