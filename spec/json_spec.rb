require 'spec_helper'

describe Faraday::HttpCache do
  let(:logger) { double('a Logger object', :debug => nil) }

  let(:client) do
    Faraday.new(:url => ENV['FARADAY_SERVER']) do |stack|
      stack.use FaradayMiddleware::ParseJson, :content_type => /\bjson$/
      stack.use :http_cache, :logger => logger
      adapter = ENV['FARADAY_ADAPTER']
      stack.headers['X-Faraday-Adapter'] = adapter
      stack.adapter adapter.to_sym
    end
  end

  it "works fine with other middlewares" do
    client.get('clear')
    client.get('json').body['count'].should == 1
    client.get('json').body['count'].should == 1
  end
end
