require 'spec_helper'

describe Faraday::HttpCache do
  let(:logger) { double('a Logger object', :debug => nil) }

  let(:client) do
    Faraday.new(:url => ENV['FARADAY_SERVER']) do |stack|
      stack.response :json, :content_type => /\bjson$/
      stack.use Faraday::HttpCache, :logger => logger
      adapter = ENV['FARADAY_ADAPTER']
      stack.headers['X-Faraday-Adapter'] = adapter
      stack.adapter adapter.to_sym
    end
  end

  before do
    client.get('clear')
  end

  it "works fine with other middlewares" do
    client.get('json').body['count'].should == 1
    client.get('json').body['count'].should == 1
  end
end