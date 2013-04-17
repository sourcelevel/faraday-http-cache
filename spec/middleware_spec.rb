require 'spec_helper'

describe Faraday::HttpCache do
  let(:logger) { double('a Logger object', :debug => nil) }

  let(:client) do
    Faraday.new(:url => ENV['FARADAY_SERVER']) do |stack|
      stack.use Faraday::HttpCache, :logger => logger
      adapter = ENV['FARADAY_ADAPTER']
      stack.headers['X-Faraday-Adapter'] = adapter
      stack.adapter adapter.to_sym
    end
  end

  before do
    client.get('clear')
  end

  it "doesn't cache POST requests" do
    client.post('post').body
    client.post('post').body.should == "2"
  end

  it "logs that a POST request is unacceptable" do
    logger.should_receive(:debug).with('HTTP Cache: [POST /post] unacceptable')
    client.post('post').body
  end

  it "doesn't cache responses with invalid status code" do
    client.get('broken')
    client.get('broken').body.should == "2"
  end

  it "logs that a response with a bad status code is invalid" do
    logger.should_receive(:debug).with('HTTP Cache: [GET /broken] miss, invalid')
    client.get('broken')
  end

  it "doesn't cache requests with a private cache control" do
    client.get('private')
    client.get('private').body.should == "2"
  end

  it "logs that a private response is invalid" do
    logger.should_receive(:debug).with('HTTP Cache: [GET /private] miss, invalid')
    client.get('private')
  end

  it "doesn't cache requests with a explicit no-store directive" do
    client.get('dontstore')
    client.get('dontstore').body.should == "2"
  end

  it "logs that a response with a no-store directive is invalid" do
    logger.should_receive(:debug).with('HTTP Cache: [GET /dontstore] miss, invalid')
    client.get('dontstore')
  end

  it "caches multiple responses when the headers differ" do
    client.get('get', nil, 'HTTP_ACCEPT' => 'text/html')
    client.get('get', nil, 'HTTP_ACCEPT' => 'text/html').body.should == "1"

    client.get('get', nil, 'HTTP_ACCEPT' => 'application/json').body.should == "2"
  end

  it "caches requests with the 'Expires' header" do
    client.get('expires')
    client.get('expires').body.should == "1"
  end

  it "logs that a request with the 'Expires' is fresh and stored" do
    logger.should_receive(:debug).with('HTTP Cache: [GET /expires] miss, store')
    client.get('expires')
  end

  it "caches GET responses" do
    client.get('get')
    client.get('get').body.should == "1"
  end

  it "logs that a GET response is stored" do
    logger.should_receive(:debug).with('HTTP Cache: [GET /get] miss, store')
    client.get('get')
  end

  it "differs requests with different query strings in the log" do
    logger.should_receive(:debug).with('HTTP Cache: [GET /get] miss, store')
    logger.should_receive(:debug).with('HTTP Cache: [GET /get?q=what] miss, store')
    client.get('get')
    client.get('get', :q => "what")
  end

  it "logs that a stored GET response is fresh" do
    client.get('get')
    logger.should_receive(:debug).with('HTTP Cache: [GET /get] fresh')
    client.get('get')
  end

  it "sends the 'Last-Modified' header on response validation" do
    client.get('timestamped')
    client.get('timestamped').body.should == "1"
  end

  it "logs that the request with 'Last-Modified' was revalidated" do
    client.get('timestamped')
    logger.should_receive(:debug).with('HTTP Cache: [GET /timestamped] valid, store')
    client.get('timestamped').body.should == "1"
  end

  it "sends the 'If-None-Match' header on response validation" do
    client.get('etag')
    client.get('etag').body.should == "1"
  end

  it "logs that the request with 'ETag' was revalidated" do
    client.get('etag')
    logger.should_receive(:debug).with('HTTP Cache: [GET /etag] valid, store')
    client.get('etag').body.should == "1"
  end

  it "maintains the 'Date' header for cached responses" do
    date = client.get('get').headers['Date']
    client.get('get').headers['Date'].should == date
  end

  it "preserves an old 'Date' header if present" do
    date = client.get('yesterday').headers['Date']
    date.should =~ /^\w{3}, \d{2} \w{3} \d{4} \d{2}:\d{2}:\d{2} GMT$/
  end

  it "updates the 'Cache-Control' header when a response is validated" do
    cache_control = client.get('etag')
    client.get('etag').headers['Cache-Control'].should_not == cache_control
  end

  it "updates the 'Date' header when a response is validated" do
    date = client.get('etag').headers['Date']
    client.get('etag').headers['Date'].should_not == date
  end

  it "updates the 'Expires' header when a response is validated" do
    expires = client.get('etag').headers['Expires']
    client.get('etag').headers['Expires'].should_not == expires
  end

  describe 'Configuration options' do
    let(:app) { double("it's an app!") }

    it 'uses the options to create a Cache Store' do
      ActiveSupport::Cache.should_receive(:lookup_store).with(:file_store, ['tmp'])
      Faraday::HttpCache.new(app, :file_store, 'tmp')
    end

    it 'accepts a Hash option' do
      ActiveSupport::Cache.should_receive(:lookup_store).with(:memory_store, { :size => 1024 })
      Faraday::HttpCache.new(app, :memory_store, :size => 1024)
    end

    it "consumes the 'logger' key" do
      ActiveSupport::Cache.should_receive(:lookup_store).with(:memory_store, {})
      Faraday::HttpCache.new(app, :memory_store, :logger => logger)
    end
  end
end
