require 'spec_helper'

describe Faraday::HttpCache::Middleware do

  let(:yesterday) {
    1.day.ago.httpdate
  }

  let(:client) do
    Faraday.new do |stack|
      stack.use Faraday::HttpCache::Middleware

      stack.adapter :test do |stubs|
        stubs.post('post')     { [200, { 'Cache-Control' => 'max-age=400' }, "#{@request_count+=1}"] }
        stubs.get('broken')    { [500, {'Cache-Control' => 'max-age=400' },  "#{@request_count+=1}"] }
        stubs.get('get')       { [200, {'Cache-Control' => 'max-age=200' },  "#{@request_count+=1}"] }
        stubs.get('private')   { [200, {'Cache-Control' => 'private' },      "#{@request_count+=1}"] }
        stubs.get('dontstore') { [200, {'Cache-Control' => 'no-store' },  "#{@request_count+=1}"] }
        stubs.get('expires')   { [200, {'Expires' => (Time.now + 10).httpdate }, "#{@request_count+=1}"]}
        stubs.get('yesterday') { [200, {'Date' => yesterday, 'Expires' => yesterday }, "#{@request_count+=1}"] }
      end
    end
  end

  before do
    @request_count = 0
  end

  it "doesn't cache POST requests" do
    client.post('post').body
    client.post('post').body.should == "2"
  end

  it "doesn't cache responses with invalid status code" do
    client.get('broken')
    client.get('broken').body.should == "2"
  end

  it "doesn't cache requests with a private cache control" do
    client.get('private')
    client.get('private').body.should == "2"
  end

  it "doesn't cache requests with a explicit no-store directive" do
    client.get('dontstore')
    client.get('dontstore').body.should == "2"
  end

  it "doesn't sets the 'Date' header for uncached responses" do
    headers = client.post('post').headers
    headers.keys.should_not include('Date')
  end

  it "caches multiple responses when the headers differ" do
    client.get('get','HTTP_ACCEPT' => 'text/html')
    client.get('get','HTTP_ACCEPT' => 'text/html').body.should == "1"

    client.get('get', 'HTTP_ACCEPT' => 'application/json').body.should == "2"
  end

  it "caches requests with the 'Expires' header" do
    client.get('expires')
    client.get('expires').body.should == "1"
  end

  it "caches GET responses" do
    client.get('get')
    client.get('get').body.should == "1"
  end

  it "maintains the 'Date' header for cached responses" do
    date = client.get('get').headers['Date']
    client.get('get').headers['Date'].should == date
  end

  it "preserves an old 'Date' header if present" do
    date = client.get('yesterday').headers['Date']
    date.should == yesterday
  end
end