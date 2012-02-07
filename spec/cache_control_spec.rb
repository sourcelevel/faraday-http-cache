require 'spec_helper'

describe Faraday::HttpCache::CacheControl do

  it 'takes a String with multiple name=value pairs' do
    instance = Faraday::HttpCache::CacheControl.new('max-age=600, max-stale=300, min-fresh=570')
    instance['max-age'].should == '600'
    instance['max-stale'].should == '300'
    instance['min-fresh'].should == '570'
  end

  it 'takes a String with a single flag value' do
    instance = Faraday::HttpCache::CacheControl.new('no-cache')
    instance.should include('no-cache')
    instance['no-cache'].should be_true
  end

  it 'takes a String with a bunch of all kinds of stuff' do
    instance =
      Faraday::HttpCache::CacheControl.new('max-age=600,must-revalidate,min-fresh=3000,foo=bar,baz')
    instance['max-age'].should == '600'
    instance['must-revalidate'].should be_true
    instance['min-fresh'].should == '3000'
    instance['foo'].should == 'bar'
    instance['baz'].should be_true
  end

  it 'strips leading and trailing spaces' do
    instance = Faraday::HttpCache::CacheControl.new('   public,   max-age =   600  ')
    instance.should include 'public'
    instance.should include 'max-age'
    instance['max-age'].should == '600'
  end

  it 'ignores blank segments' do
    instance = Faraday::HttpCache::CacheControl.new('max-age=600,,max-stale=300')
    instance['max-age'].should == '600'
    instance['max-stale'].should == '300'
  end

  it 'sorts alphabetically with boolean directives before value directives' do
    instance = Faraday::HttpCache::CacheControl.new('foo=bar, z, x, y, bling=baz, zoom=zib, b, a')
    instance.to_s.should == 'a, b, x, y, z, bling=baz, foo=bar, zoom=zib'
  end

  it 'responds to #max_age with an integer when max-age directive present' do
    instance = Faraday::HttpCache::CacheControl.new('public, max-age=600')
    instance.max_age.should == 600
  end

  it 'responds to #max_age with nil when no max-age directive present' do
    instance = Faraday::HttpCache::CacheControl.new('public')
    instance.max_age.should be_nil
  end

  it 'responds to #shared_max_age with an integer when s-maxage directive present' do
    instance = Faraday::HttpCache::CacheControl.new('public, s-maxage=600')
    instance.shared_max_age.should == 600
  end

  it 'responds to #shared_max_age with nil when no s-maxage directive present' do
    instance = Faraday::HttpCache::CacheControl.new('public')
    instance.shared_max_age.should be_nil
  end

  it 'responds to #public? truthfully when public directive present' do
    instance = Faraday::HttpCache::CacheControl.new('public')
    instance.should be_public
  end

  it 'responds to #public? non-truthfully when no public directive present' do
    instance = Faraday::HttpCache::CacheControl.new('private')
    instance.should_not be_public
  end

  it 'responds to #private? truthfully when private directive present' do
    instance = Faraday::HttpCache::CacheControl.new('private')
    instance.should be_private
  end

  it 'responds to #private? non-truthfully when no private directive present' do
    instance = Faraday::HttpCache::CacheControl.new('public')
    instance.should_not be_private
  end

  it 'responds to #no_cache? truthfully when no-cache directive present' do
    instance = Faraday::HttpCache::CacheControl.new('no-cache')
    instance.should be_no_cache
  end

  it 'responds to #no_cache? non-truthfully when no no-cache directive present' do
    instance = Faraday::HttpCache::CacheControl.new('max-age=600')
    instance.should_not be_no_cache
  end

  it 'responds to #must_revalidate? truthfully when must-revalidate directive present' do
    instance = Faraday::HttpCache::CacheControl.new('must-revalidate')
    instance.should be_must_revalidate
  end

  it 'responds to #must_revalidate? non-truthfully when no must-revalidate directive present' do
    instance = Faraday::HttpCache::CacheControl.new('max-age=600')
    instance.should_not be_no_cache
  end

  it 'responds to #proxy_revalidate? truthfully when proxy-revalidate directive present' do
    instance = Faraday::HttpCache::CacheControl.new('proxy-revalidate')
    instance.should be_proxy_revalidate
  end

  it 'responds to #proxy_revalidate? non-truthfully when no proxy-revalidate directive present' do
    instance = Faraday::HttpCache::CacheControl.new('max-age=600')
    instance.should_not be_no_cache
  end
end