require 'test_helper'
require 'dummy/config'

describe TinyClient::Configuration do
  let(:config) { Dummy::Config.instance }

  it { _(config).must_respond_to :url }
  it { _(config).must_respond_to :connect_timeout }
  it { _(config).must_respond_to :headers }
  it { _(config).must_respond_to :verbose }
  it { _(config).must_respond_to :url_for }
  it { _(config).must_respond_to :url_builder }
  it { _(config).must_respond_to :requestor }

  describe '#url_for' do
    describe 'when query params is blank' do
      it 'returns url without query' do
        _(config.url_for('organizations', 1)).must_equal 'http://localhost:3000/api/1.0/organizations/1.json'
        _(config.url_for('organizations', 1, '/permissions/1')).must_equal 'http://localhost:3000/api/1.0/organizations/1/permissions/1.json'
      end
    end

    describe 'when query params is blank' do
      it 'returns url with query' do
        _(config.url_for('organizations', 1, id: [1, 2])).must_equal 'http://localhost:3000/api/1.0/organizations/1.json?id%5B%5D=1&id%5B%5D=2'
      end
    end
  end
end
