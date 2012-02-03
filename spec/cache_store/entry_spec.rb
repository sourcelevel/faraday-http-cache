require 'spec_helper'

describe Faraday::CacheStore::Entry do

  describe 'freshness' do
    it "is fresh if the entry still has some time to live" do
      date = 200.seconds.ago.httpdate
      headers = { 'Cache-Control' => 'max-age=400', 'Date' => date }
      entry = Faraday::CacheStore::Entry.new(:response_headers => headers)

      entry.should be_fresh
    end

    it "isn't fresh when the ttl has expired" do
      date = 500.seconds.ago.httpdate
      headers = { 'Cache-Control' => 'max-age=400', 'Date' => date }
      entry = Faraday::CacheStore::Entry.new(:response_headers => headers)

      entry.should_not be_fresh
    end
  end

  describe 'max age calculation' do

    it 'uses the shared max age directive when present' do
      headers = { 'Cache-Control' => 's-maxage=200, max-age=0'}
      entry = Faraday::CacheStore::Entry.new(:response_headers => headers)
      entry.max_age.should == 200
    end

    it 'uses the max age directive when present' do
      headers = { 'Cache-Control' => 'max-age=200'}
      entry = Faraday::CacheStore::Entry.new(:response_headers => headers)
      entry.max_age.should == 200
    end

    it "fallsback to the expiration date leftovers" do
      headers = { 'Expires' => (Time.now + 100).httpdate, 'Date' => Time.now.httpdate }
      entry = Faraday::CacheStore::Entry.new(:response_headers => headers)
      entry.max_age.should == 100
    end

    it "returns nil when there's no information to calculate the max age" do
      entry = Faraday::CacheStore::Entry.new()
      entry.max_age.should be_nil
    end
  end

  describe 'age calculation' do
    it "uses the 'Age' header if it's present" do
      entry = Faraday::CacheStore::Entry.new(:response_headers => { 'Age' => '3' })
      entry.age.should == 3
    end

    it "calculates the time from the 'Date' header" do
      date = 3.seconds.ago.httpdate
      entry = Faraday::CacheStore::Entry.new(:response_headers => { 'Date' => date })
      entry.age.should == 3
    end

    it "sets the 'Date' header if isn't present and calculates the age" do
      entry = Faraday::CacheStore::Entry.new(:response_headers => {})
      entry.age.should == 0
      entry.date.should be_present
    end
  end

  describe 'time to live calculation' do
    it "returns the time to live based on the max age limit" do
      date = 200.seconds.ago.httpdate
      headers = { 'Cache-Control' => 'max-age=400', 'Date' => date }
      entry = Faraday::CacheStore::Entry.new(:response_headers => headers)
      entry.ttl.should == 200
    end
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