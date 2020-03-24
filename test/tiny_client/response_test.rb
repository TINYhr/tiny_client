require 'test_helper'

describe TinyClient::Response do
  let(:header_str) { '' }
  let(:body) { '' }
  let(:status) { '' }

  let(:response) { TinyClient::Response.new(curb) }
  let(:curb) { mock }

  before do
    curb.responds_like_instance_of(Curl::Easy)
    curb.stubs(body_str: body.to_json, status: status, header_str: header_str, url: 'toto')
  end

  describe '#not_found_error?' do
    describe 'when HTTP status is 404' do
      let(:status) { '404 NOT FOUND' }
      it { response.not_found_error?.must_equal true }
    end

    describe 'when HTTP status is not 404' do
      let(:status) { '200 OK' }
      it { response.not_found_error?.must_equal false }
    end

    describe 'when HTTP status is 500' do
      let(:status) { '500 Internal Server Error' }
      it { response.not_found_error?.must_equal false }
    end
  end

  describe '#to_hash' do
    let(:header_str) { "HTTP/1.1 200 OK\r\nContent-Type: application/json; charset=utf-8\r\n" }
    let(:body) { { data: { message: 'OK' }, error: false } }
    let(:status) { '200 OK' }

    it 'includes url' do
      response.to_hash['url'].must_equal('toto')
    end

    it 'includes status' do
      response.to_hash['status'].must_equal('200 OK')
    end

    it 'includes parsed body' do
      response.to_hash['body'].must_equal({ 'data' => { 'message' => 'OK' }, 'error' => false })
    end

    it 'includes parsed headers' do
      response.to_hash['headers'].must_equal({ 'Content-Type' => 'application/json; charset=utf-8' })
    end
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
        response.parse_body.must_equal body
      end
    end
  end

  describe 'when curb contains a failed (404) response with a json body' do
    let(:body) { { error: 'Not Found' } }
    let(:status) { '404 NOT FOUND' }

    it 'create a successful response' do
      response.success?.must_equal false
      response.error?.must_equal true
      response.not_found_error?.must_equal true
      response.client_error?.must_equal true
      response.code.must_equal 404
      response.parse_body.must_equal body.stringify_keys
      response.url.must_equal 'toto'
    end
  end

  describe 'when curb contains X-Total-Count header' do
    let(:header_str) { 'adfafdafd X-Total-Count: 202' }
    it { response.total_count.must_equal 202 }
  end

  describe 'when curb do not contains X-Total-Count header' do
    let(:header_str) { 'adfafdafd' }
    it { response.total_count.must_be :nil? }
  end
end
