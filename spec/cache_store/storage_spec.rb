require 'spec_helper'

describe Faraday::CacheStore::Storage do

  let(:backend) { double('A cache backend') }

  let(:request) do
    { :method => :get, :request_headers => {}, :url => URI.parse("http://foo.bar/") }
  end

  let(:response) do
   { :status => 200, :body => "Hi!", :response_headers => {} }
  end

  let(:json_response) { MultiJson.encode(response) }

  subject { described_class.new(backend) }

  describe 'writing to the backend cache object' do
    it 'encodes the request as a SHA1 key and the response as a JSON string' do
      backend.should_receive(:write).with('a41588bc25996b8dc390d145d7e752a0006f7101', json_response)
      subject.write(request, response)
    end
  end

  describe 'reading from the backend cache object' do
    it 'uses the SHA1 representation from the request a the key' do
      backend.should_receive(:read).with('a41588bc25996b8dc390d145d7e752a0006f7101') { json_response }
      subject.read(request)
    end

    it 'decodes the stored JSON string' do
      backend.stub(:read) { json_response }
      subject.read(request).should == response
    end

    it "returns nil if the key isn't present" do
      backend.stub(:read) { nil }
      subject.read(request).should be_nil
    end
  end
end