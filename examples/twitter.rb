require 'rubygems'
require 'bundler/setup'

require 'faraday/http_cache'

# Twitter says we can cache their response for 5 minutes.
maxage = 300

@client = Faraday.new('http://api.twitter.com') do |builder|
  builder.use Faraday::HttpCache
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

maxage.downto(0) do |remaining|
  print "Let's wait #{remaining} second#{'s' unless remaining == 1} for the cache to expire...\r"
  sleep 1
end

puts "\nRequesting 'http://api.twitter.com/1/trends/daily.json' again...\n"
puts "   1 - #{make_request} requests remaining."
puts "   2 - #{make_request} requests remaining."
puts "   3 - #{make_request} requests remaining."
