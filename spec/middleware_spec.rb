require 'spec_helper'

describe Faraday::HttpCache do
  let(:yesterday) { 1.day.ago.httpdate }

  let(:logger) { double('a Logger object', :debug => nil) }

  let(:client) do
    Faraday.new do |stack|
      stack.use Faraday::HttpCache, :logger => logger

      stack.adapter :test do |stubs|
        stubs.post('/post')     { [200, { 'Cache-Control' => 'max-age=400' },            "#{@request_count += 1}"] }
        stubs.get('/broken')    { [500, { 'Cache-Control' => 'max-age=400' },            "#{@request_count += 1}"] }
        stubs.get('/get')       { [200, { 'Cache-Control' => 'max-age=200' },            "#{@request_count += 1}"] }
        stubs.get('/private')   { [200, { 'Cache-Control' => 'private' },                "#{@request_count += 1}"] }
        stubs.get('/dontstore') { [200, { 'Cache-Control' => 'no-store' },               "#{@request_count += 1}"] }
        stubs.get('/expires')   { [200, { 'Expires' => (Time.now + 10).httpdate },       "#{@request_count += 1}"] }
        stubs.get('/yesterday') { [200, { 'Date' => yesterday, 'Expires' => yesterday }, "#{@request_count += 1}"] }

        stubs.get('/timestamped') do |env|
          @counter += 1
          header = @counter > 2 ? '1' : '2'

          if env[:request_headers]['If-Modified-Since'] == header
            [304, {}, ""]
          else
            [200, {'Last-Modified' => header}, "#{@request_count += 1}"]
          end
        end

        stubs.get('/etag') do |env|
          @counter += 1
          tag = @counter > 2 ? '1' : '2'

          if env[:request_headers]['If-None-Match'] == tag
            [304, {}, ""]
          else
            [200, {'ETag' => tag}, "#{@request_count += 1}"]
          end
        end
      end
    end
  end

  before do
    @request_count = 0
    @counter = 0
  end

  it "doesn't cache POST requests" do
    client.post('/post').body
    client.post('/post').body.should == "2"
  end

  it "logs that a POST request is unacceptable" do
    logger.should_receive(:debug).with('HTTP Cache: [POST /post] unacceptable')
    client.post('/post').body
  end

  it "doesn't cache responses with invalid status code" do
    client.get('/broken')
    client.get('/broken').body.should == "2"
  end

  it "logs that a response with a bad status code is invalid" do
    logger.should_receive(:debug).with('HTTP Cache: [GET /broken] miss, invalid')
    client.get('/broken')
  end

  it "doesn't cache requests with a private cache control" do
    client.get('/private')
    client.get('/private').body.should == "2"
  end

  it "logs that a private response is invalid" do
    logger.should_receive(:debug).with('HTTP Cache: [GET /private] miss, invalid')
    client.get('/private')
  end

  it "doesn't cache requests with a explicit no-store directive" do
    client.get('/dontstore')
    client.get('/dontstore').body.should == "2"
  end

  it "logs that a response with a no-store directive is invalid" do
    logger.should_receive(:debug).with('HTTP Cache: [GET /dontstore] miss, invalid')
    client.get('/dontstore')
  end

  it "doesn't sets the 'Date' header for uncached responses" do
    headers = client.post('/post').headers
    headers.keys.should_not include('Date')
  end

  it "caches multiple responses when the headers differ" do
    client.get('/get','HTTP_ACCEPT' => 'text/html')
    client.get('/get','HTTP_ACCEPT' => 'text/html').body.should == "1"

    client.get('/get', 'HTTP_ACCEPT' => 'application/json').body.should == "2"
  end

  it "caches requests with the 'Expires' header" do
    client.get('/expires')
    client.get('/expires').body.should == "1"
  end

  it "logs that a request with the 'Expires' is fresh and stored" do
    logger.should_receive(:debug).with('HTTP Cache: [GET /expires] miss, store')
    client.get('/expires')
  end

  it "caches GET responses" do
    client.get('/get')
    client.get('/get').body.should == "1"
  end

  it "logs that a GET response is stored" do
    logger.should_receive(:debug).with('HTTP Cache: [GET /get] miss, store')
    client.get('/get')
  end

  it "logs that a stored GET response is fresh" do
    client.get('/get')
    logger.should_receive(:debug).with('HTTP Cache: [GET /get] fresh')
    client.get('/get')
  end

  it "sends the 'Last-Modified' header on response validation" do
    client.get('/timestamped')
    client.get('/timestamped').body.should == "1"
  end

  it "logs that the request with 'Last-Modified' was revalidated" do
    client.get('/timestamped')
    logger.should_receive(:debug).with('HTTP Cache: [GET /timestamped] valid, store')
    client.get('/timestamped').body.should == "1"
  end

  it "sends the 'If-None-Match' header on response validation" do
    client.get('/etag')
    client.get('/etag').body.should == "1"
  end

  it "logs that the request with 'ETag' was revalidated" do
    client.get('/etag')
    logger.should_receive(:debug).with('HTTP Cache: [GET /etag] valid, store')
    client.get('/etag').body.should == "1"
  end

  it "maintains the 'Date' header for cached responses" do
    date = client.get('/get').headers['Date']
    client.get('/get').headers['Date'].should == date
  end

  it "preserves an old 'Date' header if present" do
    date = client.get('/yesterday').headers['Date']
    date.should == yesterday
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
      logger = double('a logger object')
      ActiveSupport::Cache.should_receive(:lookup_store).with(:memory_store, {})
      Faraday::HttpCache.new(app, :memory_store, :logger => logger)
    end
  end
end
