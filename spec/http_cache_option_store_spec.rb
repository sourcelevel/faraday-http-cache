require 'spec_helper'

describe Faraday::HttpCache do

  let(:app) { double('it is an app!') }

  it 'when options[:store] is nil' do
    http_cache = Faraday::HttpCache.new(app, {})

    expect(http_cache.instance_variable_get(:@storage)).to be_a(Faraday::HttpCache::Storage)
  end

  it 'when options[:store] is not nil and not a Storage instance' do
    store = double(read: nil, write: nil, delete: nil)
    http_cache = Faraday::HttpCache.new(app, {store: store})

    expect(http_cache.instance_variable_get(:@storage)).to be_a(Faraday::HttpCache::Storage)
  end

  it 'when options[:store] is a Storage instance' do
    store = Faraday::HttpCache::Storage.new
    http_cache = Faraday::HttpCache.new(app, {store: store})

    expect(http_cache.instance_variable_get(:@storage)).to be_a(Faraday::HttpCache::Storage)
  end

end
