require 'spec_helper'

describe Faraday::HttpCache::Storage do
  let(:request) do
    { method: :get, request_headers: {}, url: URI.parse("http://foo.bar/") }
  end

  let(:response) { double(serializable_hash: {}) }

  let(:cache) { ActiveSupport::Cache.lookup_store }

  subject { Faraday::HttpCache::Storage.new(cache) }

  describe 'Cache configuration' do
    it 'lookups a ActiveSupport cache store' do
      expect(ActiveSupport::Cache).to receive(:lookup_store).with(:file_store, '/tmp')
      Faraday::HttpCache::Storage.new(:file_store, '/tmp')
    end
  end

  describe 'storing responses' do
    it 'writes the response json to the underlying cache using a digest as the key' do
      json = MultiJson.dump(response.serializable_hash)

      expect(cache).to receive(:write).with('503ac9f7180ca1cdec49e8eb73a9cc0b47c27325', json)
      subject.write(request, response)
    end
  end

  describe 'reading responses' do
    it "returns nil if the response isn't cached" do
      expect(subject.read(request)).to be_nil
    end

    it 'decodes a stored response' do
      subject.write(request, response)

      expect(subject.read(request)).to be_a(Faraday::HttpCache::Response)
    end
  end

  describe 'remove age before caching and normalize max-age if non-zero age present' do
    it 'is fresh if the response still has some time to live' do
      headers = {
          'Age' => 6,
          'Cache-Control' => 'public, max-age=40',
          'Date' => 38.seconds.ago.httpdate,
          'Expires' => 37.seconds.from_now.httpdate,
          'Last-Modified' => 300.seconds.ago.httpdate
      }
      response = Faraday::HttpCache::Response.new(response_headers: headers)
      expect(response).to be_fresh
      subject.write(request, response)

      cached_response = subject.read(request)
      expect(cached_response.max_age).to eq(34)
      expect(cached_response).not_to be_fresh
    end

    it 'is fresh until cached and that 1 second elapses then the response is no longer fresh' do
      headers = {
          'Date' => 39.seconds.ago.httpdate,
          'Expires' => 40.seconds.from_now.httpdate,
      }
      response = Faraday::HttpCache::Response.new(response_headers: headers)
      expect(response).to be_fresh
      subject.write(request, response)

      sleep(1)
      cached_response = subject.read(request)
      expect(cached_response).not_to be_fresh
    end
  end

end
