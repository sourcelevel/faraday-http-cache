require 'rubygems'
require 'bundler/setup'

require 'faraday/http_cache'
require 'active_support/logger'
require 'faraday_middleware'

client = Faraday.new('https://api.github.com') do |stack|
  stack.response :json, content_type: /\bjson$/
  stack.use :http_cache, logger: ActiveSupport::Logger.new(STDOUT)
  stack.adapter Faraday.default_adapter
end

5.times do |index|
  started = Time.now
  puts "Request ##{index+1}"
  response = client.get('repos/plataformatec/faraday-http-cache')
  finished = Time.now
  remaining = response.headers['X-RateLimit-Remaining']
  limit = response.headers['X-RateLimit-Limit']

  puts "  Request took #{(finished - started) * 1000} ms."
  puts "  Rate limits: remaining #{remaining} requests of #{limit}."
end
