require 'rubygems'
require 'bundler/setup'

require 'faraday/http_cache'
require 'active_support/logger'
require 'em-http-request'

client = Faraday.new('https://api.github.com') do |stack|
  stack.use :http_cache, logger: ActiveSupport::Logger.new($stdout)
  stack.adapter :em_http
end

2.times do
  started = Time.now
  client.in_parallel do
    client.get('repos/plataformatec/faraday-http-cache')
    client.get('repos/lostisland/faraday')
  end
  finished = Time.now

  puts "  Parallel requests done! #{(finished - started) * 1000} ms."
  puts
end
