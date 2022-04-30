require 'rubygems'
require 'bundler/setup'

require 'faraday/http_cache'
require 'faraday/em_http'
require 'active_support'
require 'active_support/logger'

# To execute run:
# FARADAY_ADAPTER=em_http FARADAY_VERSION='~> 1.0' bash -c 'bundle && bundle exec ruby examples/parallel.rb'
client = Faraday.new('https://api.github.com') do |stack|
  stack.use :http_cache, logger: ActiveSupport::Logger.new($stdout)
  stack.adapter :em_http
end

2.times do
  started = Time.now
  client.in_parallel do
    client.get('repos/sourcelevel/faraday-http-cache')
    client.get('repos/lostisland/faraday')
  end
  finished = Time.now

  puts "  Parallel requests done! #{(finished - started) * 1000} ms."
  puts
end
