require 'spec_helper'

describe Faraday::CacheStore::Entry do

  describe 'freshness' do
    it "it's fresh if the max-age from the response hasn't expired yet"
  end

  describe "response unboxing" do
    subject { described_class.new(:status => 200, :response_headers => {}, :body => 'Hi!') }
    let(:response) { subject.to_response }

    it 'returns a Faraday::Response' do
      response.should be_a Faraday::Response
    end

    it 'merges the status code' do
      response.status.should == 200
    end

    it 'merges the headers' do
      response.headers.should == {}
    end

    it 'merges the body' do
      response.body.should == "Hi!"
    end
  end
end