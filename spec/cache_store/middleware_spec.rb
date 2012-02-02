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

  [:get, :head].each do |method|
    it "tries to cache #{method} requests" do
      storage.should_receive(:read)
      valid_request = request.merge(:method => method)
      subject.call(valid_request)
    end
  end

  [:post, :put, :delete, :patch, :options].each do |invalid_method|
    it "doesn't store #{invalid_method} requests" do
      storage.should_not_receive(:read)
      storage.should_not_receive(:write)
      unacceptable_request = request.merge(:method => invalid_method)
      subject.call(unacceptable_request)
    end
  end

  it 'stores the request and the response' do
    storage.should_receive(:write).with(request, serializable_response)
    subject.call(request)
  end

  it 'sets the request timestamp when writing' do
    storage.should_receive(:write).with(request, hash_including(:timestamp))
    subject.call(request)
  end

  it 'calls the underlying application just once if the storage has the response' do
    app.should_receive(:call).once
    subject.call(request)
    storage.stub(:read) { serializable_response }
    subject.call(request)
  end
end