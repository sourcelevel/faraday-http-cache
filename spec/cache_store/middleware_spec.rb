require 'spec_helper'

describe Faraday::CacheStore::Middleware do

  let(:request) do
    { :method => :get, :request_headers => {}, :url => URI.parse("http://foo.bar/") }
  end

  let(:serializable_response) { Hash.new }
  let(:response) { double('a response instance', :marshal_dump => serializable_response) }

  let(:app) { double('', :call => response) }
  let(:storage) { double('The cache storage', :read => nil, :write => nil) }
  subject { described_class.new(app, storage) }

  it 'stores the request and the response' do
    storage.should_receive(:write).with(request, serializable_response)
    subject.call(request)
  end

  it 'calls the underlying application just once if the storage has the response' do
    app.should_receive(:call).once
    subject.call(request)
    storage.stub(:read) { serializable_response }
    subject.call(request)
  end
end