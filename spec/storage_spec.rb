require 'spec_helper'

describe Faraday::HttpCache::Storage do
  let(:request) do
    { method: :get, request_headers: {}, url: URI.parse('http://foo.bar/') }
  end

  let(:response) { double(serializable_hash: {}) }

  let(:cache) { ActiveSupport::Cache.lookup_store }

  let(:storage) { Faraday::HttpCache::Storage.new(store: cache) }
  subject { storage }

  describe 'Cache configuration' do
    it 'lookups a ActiveSupport cache store' do
      expect(ActiveSupport::Cache).to receive(:lookup_store).with(:file_store, ['/tmp'])
      Faraday::HttpCache::Storage.new(store: :file_store, store_options: ['/tmp'])
    end

    it 'emits a warning when using the "MemoryStore"' do
      logger = double
      expect(logger).to receive(:warn).with(/using a MemoryStore is not advised/)
      Faraday::HttpCache::Storage.new(logger: logger)
    end
  end

  describe 'storing responses' do

    shared_examples 'serialization' do
      it 'writes the response json to the underlying cache using a digest as the key' do
        expect(cache).to receive(:write).with(cache_key, serialized)
        subject.write(request, response)
      end
    end

    context 'with default serializer' do
      let(:serialized) { MultiJson.dump(response.serializable_hash) }
      let(:cache_key)  { '503ac9f7180ca1cdec49e8eb73a9cc0b47c27325' }
      it_behaves_like 'serialization'
    end

    context 'with Marshal serializer' do
      let(:storage)    { Faraday::HttpCache::Storage.new store: cache, serializer: Marshal }
      let(:serialized) { Marshal.dump(response.serializable_hash) }
      let(:cache_key) do
        array = request.stringify_keys.to_a.sort
        Digest::SHA1.hexdigest(Marshal.dump(array))
      end
      it_behaves_like 'serialization'
    end

  end

  describe 'reading responses' do
    it 'returns nil if the response is not cached' do
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
