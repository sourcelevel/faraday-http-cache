require 'spec_helper'

describe Faraday::HttpCache::Middleware do

  let(:yesterday) {
    1.day.ago.httpdate
  }

  let(:logger) {
    double('a Logger object', :debug => nil)
  }

  let(:client) do
    Faraday.new do |stack|
      stack.use Faraday::HttpCache::Middleware, :logger => logger

      stack.adapter :test do |stubs|
        stubs.post('/post')     { [200, { 'Cache-Control' => 'max-age=400' },            "#{@request_count+=1}"] }
        stubs.get('/broken')    { [500, { 'Cache-Control' => 'max-age=400' },            "#{@request_count+=1}"] }
        stubs.get('/get')       { [200, { 'Cache-Control' => 'max-age=200' },            "#{@request_count+=1}"] }
        stubs.get('/private')   { [200, { 'Cache-Control' => 'private' },                "#{@request_count+=1}"] }
        stubs.get('/dontstore') { [200, { 'Cache-Control' => 'no-store' },               "#{@request_count+=1}"] }
        stubs.get('/expires')   { [200, { 'Expires' => (Time.now + 10).httpdate },       "#{@request_count+=1}"] }
        stubs.get('/yesterday') { [200, { 'Date' => yesterday, 'Expires' => yesterday }, "#{@request_count+=1}"] }
      end
    end
  end

  before do
    @request_count = 0
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
    logger.should_receive(:debug).with('HTTP Cache: [GET /get] fresh, store')
    client.get('/get')
  end

  it "maintains the 'Date' header for cached responses" do
    date = client.get('/get').headers['Date']
    client.get('/get').headers['Date'].should == date
  end

  it "preserves an old 'Date' header if present" do
    date = client.get('/yesterday').headers['Date']
    date.should == yesterday
  end
end