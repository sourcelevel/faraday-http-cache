require 'spec_helper'

describe Faraday::CacheStore::Middleware do

  let(:client) do
    Faraday.new do |stack|
      stack.use :cache_store

      stack.adapter :test do |stubs|
        stubs.post('post')   { [200, { 'Cache-Control' => 'max-age=400' }, "post:#{@post_count+=1}"] }
        stubs.get('broken')  { [500, {'Cache-Control' => 'max-age=400' },  "broken:#{@broken_count+=1}"] }
        stubs.get('get')     { [200, {'Cache-Control' => 'max-age=200' },  "get:#{@get_count+=1}"] }
        stubs.get('private') { [200, {'Cache-Control' => 'private' },      "get:#{@get_count+=1}"] }
      end
    end
  end

  before do
    @post_count = 0
    @broken_count = 0
    @get_count = 0
  end

  it "doesn't cache POST requests" do
    client.post('post').body
    client.post('post').body.should == "post:2"
  end

  it "doesn't cache responses with invalid status code" do
    client.get('broken')
    client.get('broken').body.should == "broken:2"
  end

  it "doesn't cache requests with a private cache control" do
    client.get('private')
    client.get('private').body.should == "get:2"
  end

  it "caches GET responses" do
    client.get('get')
    client.get('get').body.should == "get:1"
  end
end