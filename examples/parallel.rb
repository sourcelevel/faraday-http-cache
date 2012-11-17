require 'logger'
require 'rubygems'
require 'bundler/setup'

require 'faraday/http_cache'
require 'em-http-request'

client = Faraday.new('http://api.twitter.com') do |builder|
  builder.use Faraday::HttpCache, :logger => Logger.new(STDOUT)
  builder.adapter :em_http
end

daily, weekly = nil, nil

started = Time.now
client.in_parallel do
  client.get("/1/trends/daily.json")
  client.get("/1/trends/weekly.json")
end
finished = Time.now

puts "Parallel requests done! #{(finished - started) * 1000} ms."

sleep 5

started = Time.now
client.in_parallel do
  client.get("/1/trends/daily.json")
  client.get("/1/trends/weekly.json")
end
finished = Time.now

puts "Parallel requests done! #{(finished - started) * 1000} ms."
