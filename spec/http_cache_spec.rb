require 'spec_helper'

describe Faraday::HttpCache do
  let(:logger) { double('a Logger object', debug: nil, warn: nil) }
  let(:options) { { logger: logger } }

  let(:client) do
    Faraday.new(url: ENV['FARADAY_SERVER']) do |stack|
      stack.use Faraday::HttpCache, options
      adapter = ENV['FARADAY_ADAPTER']
      stack.headers['X-Faraday-Adapter'] = adapter
      stack.adapter adapter.to_sym
    end
  end

  before do
    client.get('clear')
  end

  it 'does not cache POST requests' do
    client.post('post').body
    expect(client.post('post').body).to eq('2')
  end

  it 'logs that a POST request is unacceptable' do
    expect(logger).to receive(:debug).with('HTTP Cache: [POST /post] unacceptable, delete')
    client.post('post').body
  end

  it 'does not cache responses with invalid status code' do
    client.get('broken')
    expect(client.get('broken').body).to eq('2')
  end

  it 'expires POST requests' do
    client.get('counter')
    client.post('counter')
    expect(client.get('counter').body).to eq('2')
  end

  it 'logs that a POST request was deleted from the cache' do
    expect(logger).to receive(:debug).with('HTTP Cache: [POST /counter] unacceptable, delete')
    client.post('counter')
  end

  it 'does not expires POST requests that failed' do
    client.get('get')
    client.post('get')
    expect(client.get('get').body).to eq('1')
  end

  it 'expires PUT requests' do
    client.get('counter')
    client.put('counter')
    expect(client.get('counter').body).to eq('2')
  end

  it 'logs that a PUT request was deleted from the cache' do
    expect(logger).to receive(:debug).with('HTTP Cache: [PUT /counter] unacceptable, delete')
    client.put('counter')
  end

  it 'expires DELETE requests' do
    client.get('counter')
    client.delete('counter')
    expect(client.get('counter').body).to eq('2')
  end

  it 'logs that a DELETE request was deleted from the cache' do
    expect(logger).to receive(:debug).with('HTTP Cache: [DELETE /counter] unacceptable, delete')
    client.delete('counter')
  end

  it 'expires PATCH requests' do
    client.get('counter')
    client.patch('counter')
    expect(client.get('counter').body).to eq('2')
  end

  it 'logs that a PATCH request was deleted from the cache' do
    expect(logger).to receive(:debug).with('HTTP Cache: [PATCH /counter] unacceptable, delete')
    client.patch('counter')
  end

  it 'logs that a response with a bad status code is invalid' do
    expect(logger).to receive(:debug).with('HTTP Cache: [GET /broken] miss, invalid')
    client.get('broken')
  end

  describe 'when acting as a shared cache' do
    let(:options) { { logger: logger, shared_cache: true } }

    it 'does not cache requests with a private cache control' do
      client.get('private')
      expect(client.get('private').body).to eq('2')
    end

    it 'logs that a private response is invalid' do
      expect(logger).to receive(:debug).with('HTTP Cache: [GET /private] miss, invalid')
      client.get('private')
    end
  end

  describe 'when acting as a private cache' do
    let(:options) { { logger: logger, shared_cache: false } }

    it 'does cache requests with a private cache control' do
      client.get('private')
      expect(client.get('private').body).to eq('1')
    end

    it 'logs that a private response is stored' do
      expect(logger).to receive(:debug).with('HTTP Cache: [GET /private] miss, store')
      client.get('private')
    end
  end

  it 'does not cache requests with a explicit no-store directive' do
    client.get('dontstore')
    expect(client.get('dontstore').body).to eq('2')
  end

  it 'logs that a response with a no-store directive is invalid' do
    expect(logger).to receive(:debug).with('HTTP Cache: [GET /dontstore] miss, invalid')
    client.get('dontstore')
  end

  it 'caches multiple responses when the headers differ' do
    client.get('get', nil, 'HTTP_ACCEPT' => 'text/html')
    expect(client.get('get', nil, 'HTTP_ACCEPT' => 'text/html').body).to eq('1')
    expect(client.get('get', nil, 'HTTP_ACCEPT' => 'application/json').body).to eq('2')
  end

  it 'caches requests with the "Expires" header' do
    client.get('expires')
    expect(client.get('expires').body).to eq('1')
  end

  it 'logs that a request with the "Expires" is fresh and stored' do
    expect(logger).to receive(:debug).with('HTTP Cache: [GET /expires] miss, store')
    client.get('expires')
  end

  it 'caches GET responses' do
    client.get('get')
    expect(client.get('get').body).to eq('1')
  end

  it 'logs that a GET response is stored' do
    expect(logger).to receive(:debug).with('HTTP Cache: [GET /get] miss, store')
    client.get('get')
  end

  it 'differs requests with different query strings in the log' do
    expect(logger).to receive(:debug).with('HTTP Cache: [GET /get] miss, store')
    expect(logger).to receive(:debug).with('HTTP Cache: [GET /get?q=what] miss, store')
    client.get('get')
    client.get('get', q: 'what')
  end

  it 'logs that a stored GET response is fresh' do
    client.get('get')
    expect(logger).to receive(:debug).with('HTTP Cache: [GET /get] fresh')
    client.get('get')
  end

  it 'sends the "Last-Modified" header on response validation' do
    client.get('timestamped')
    expect(client.get('timestamped').body).to eq('1')
  end

  it 'logs that the request with "Last-Modified" was revalidated' do
    client.get('timestamped')
    expect(logger).to receive(:debug).with('HTTP Cache: [GET /timestamped] valid, store')
    expect(client.get('timestamped').body).to eq('1')
  end

  it 'sends the "If-None-Match" header on response validation' do
    client.get('etag')
    expect(client.get('etag').body).to eq('1')
  end

  it 'logs that the request with "ETag" was revalidated' do
    client.get('etag')
    expect(logger).to receive(:debug).with('HTTP Cache: [GET /etag] valid, store')
    expect(client.get('etag').body).to eq('1')
  end

  it 'maintains the "Date" header for cached responses' do
    first_date = client.get('get').headers['Date']
    second_date = client.get('get').headers['Date']
    expect(first_date).to eq(second_date)
  end

  it 'preserves an old "Date" header if present' do
    date = client.get('yesterday').headers['Date']
    expect(date).to match(/^\w{3}, \d{2} \w{3} \d{4} \d{2}:\d{2}:\d{2} GMT$/)
  end

  it 'updates the "Cache-Control" header when a response is validated' do
    first_cache_control  = client.get('etag').headers['Cache-Control']
    second_cache_control = client.get('etag').headers['Cache-Control']
    expect(first_cache_control).not_to eql(second_cache_control)
  end

  it 'updates the "Date" header when a response is validated' do
    first_date  = client.get('etag').headers['Date']
    second_date = client.get('etag').headers['Date']
    expect(first_date).not_to eql(second_date)
  end

  it 'updates the "Expires" header when a response is validated' do
    first_expires  = client.get('etag').headers['Expires']
    second_expires = client.get('etag').headers['Expires']
    expect(first_expires).not_to eql(second_expires)
  end

  it 'updates the "Vary" header when a response is validated' do
    first_vary  = client.get('etag').headers['Vary']
    second_vary = client.get('etag').headers['Vary']
    expect(first_vary).not_to eql(second_vary)
  end

  it 'raises an error when misconfigured' do
    expect {
      client = Faraday.new(url: ENV['FARADAY_SERVER']) do |stack|
        stack.use Faraday::HttpCache, i_have_no_idea: true
      end

      client.get('get')
    }.to raise_error(ArgumentError)
  end

  describe 'Configuration options' do
    let(:app) { double('it is an app!') }

    it 'uses the options to create a Cache Store' do
      store = double(read: nil, write: nil)

      expect(Faraday::HttpCache::Storage).to receive(:new).with(store: store)
      Faraday::HttpCache.new(app, store: store)
    end

    it 'accepts a Hash option' do
      expect(ActiveSupport::Cache).to receive(:lookup_store).with(:memory_store, [{ size: 1024 }]).and_call_original
      Faraday::HttpCache.new(app, store: :memory_store, store_options: [size: 1024])
    end

    it 'consumes the "logger" key' do
      expect(ActiveSupport::Cache).to receive(:lookup_store).with(:memory_store, nil).and_call_original
      Faraday::HttpCache.new(app, store: :memory_store, logger: logger)
    end

    context 'with deprecated options format' do
      before do
        allow(Kernel).to receive(:warn)
      end

      it 'uses the options to create a Cache Store' do
        expect(ActiveSupport::Cache).to receive(:lookup_store).with(:file_store, ['tmp']).and_call_original
        Faraday::HttpCache.new(app, :file_store, 'tmp')
      end

      it 'accepts a Hash option' do
        expect(ActiveSupport::Cache).to receive(:lookup_store).with(:memory_store, [{ size: 1024 }]).and_call_original
        Faraday::HttpCache.new(app, :memory_store, size: 1024)
      end

      it 'warns the user about the deprecated options' do
        expect(Kernel).to receive(:warn)

        Faraday::HttpCache.new(app, :memory_store, logger: logger)
      end
    end
  end
end
