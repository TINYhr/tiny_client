require 'test_helper'

describe TinyClient::Response do
  let(:response) { TinyClient::Response.new(curb) }
  let(:curb) { mock }

  before do
    curb.responds_like_instance_of(Curl::Easy)
    curb.stubs(body_str: body.to_json, status: status, header_str: '', url: 'toto' )
  end

  describe 'when curb contains a successful (200) json response' do
    let(:body) { { 'toto' => 'Tata' } }
    let(:status) { '200 OK' }

    it 'create a successful response' do
      response.must_be :success?
      response.code.must_equal 200
      response.url.must_equal 'toto'
    end

    describe '#parse_body' do
      it 'create the proper response body object' do
        response.parse_body.must_equal OpenStruct.new(body)
        response.parse_body(Hash).must_equal body
      end
    end
  end

  describe 'when curb contains a failed (404) response with a json body' do
    let(:body) { { error: 'Not Found' } }
    let(:status) { '404 NOT FOUND' }

    it 'create a successful response' do
      response.success?.must_equal false
      response.error?.must_equal true
      response.client_error?.must_equal true
      response.code.must_equal 404
      response.parse_body.must_equal OpenStruct.new(body)
      response.url.must_equal 'toto'
    end
  end
end
