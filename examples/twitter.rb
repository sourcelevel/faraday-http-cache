require 'rubygems'
$:.unshift File.expand_path('../lib', File.dirname(__FILE__))
require 'faraday/http_cache'

@client = Faraday.new('http://api.twitter.com') do |builder|
  builder.use Faraday::HttpCache::Middleware
  builder.adapter Faraday.default_adapter
end

def make_request
  response = @client.get('/1/trends/daily.json')
  response.headers['X-RateLimit-Remaining']
end

puts "Requesting 'http://api.twitter.com/1/trends/daily.json' a few times...\n"

puts "   1 - #{make_request} requests remaining."
puts "   2 - #{make_request} requests remaining."
puts "   3 - #{make_request} requests remaining."

puts "\nLet's wait 300 seconds for the cache to expire...\n"
sleep 300

puts "\nRequesting 'http://api.twitter.com/1/trends/daily.json' again...\n"
puts "   1 - #{make_request} requests remaining."
puts "   2 - #{make_request} requests remaining."
