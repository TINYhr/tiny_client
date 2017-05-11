require 'test_helper'

describe TinyClient::UrlBuilder do
  describe '#path' do
    let(:url_builder) { TinyClient::UrlBuilder.url('/organizations') }

    it 'removes ".json" suffix in path' do
      url = TinyClient::UrlBuilder
              .url('/organizations')
              .path(1)
              .path('permissions/1.json').build!
      url.must_equal '/organizations/1/permissions/1.json'

      url = TinyClient::UrlBuilder
              .url('/organizations')
              .path(1)
              .path('roles/1.json')
              .path('permissions/1.json').build!
      url.must_equal '/organizations/1/roles/1/permissions/1.json'
    end
  end
end
