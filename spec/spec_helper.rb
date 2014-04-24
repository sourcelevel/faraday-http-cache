require 'uri'
require 'socket'

require 'faraday-http-cache'
require 'faraday_middleware'
require 'sham_rack'

# https://github.com/rails/rails/pull/14667
require 'active_support/per_thread_registry'
require 'active_support/cache'

require 'support/test_app'

ShamRack.at('faraday-http-cache.local').rackup do
  run TestApp.new
end

ENV['FARADAY_ADAPTER'] ||= 'net_http'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.order = 'random'
end
