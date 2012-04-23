require 'spec_helper'

describe Faraday::HttpCache::Storage do
  let(:request) do
    { :method => :get, :request_headers => {}, :url => URI.parse("http://foo.bar/") }
  end

  let(:response) { double(:payload => {}) }

  let(:cache) { ActiveSupport::Cache.lookup_store }

  subject { Faraday::HttpCache::Storage.new(cache) }

  describe 'Cache configuration' do
    it 'lookups a ActiveSupport cache store' do
      ActiveSupport::Cache.should_receive(:lookup_store).with(:file_store, '/tmp')
      Faraday::HttpCache::Storage.new(:file_store, '/tmp')
    end
  end

  describe 'storing responses' do
    it 'writes the response json to the underlying cache using a digest as the key' do
      json = MultiJson.dump(response.payload)

      cache.should_receive(:write).with('503ac9f7180ca1cdec49e8eb73a9cc0b47c27325', json)
      subject.write(request, response)
    end
  end

  describe 'reading responses' do
    it "returns nil if the response isn't cached" do
      subject.read(request).should be_nil
    end

    it 'decodes a stored response' do
      subject.write(request, response)

      subject.read(request).should be_a(Faraday::HttpCache::Response)
    end
  end
end
