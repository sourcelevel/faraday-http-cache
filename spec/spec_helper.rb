require 'uri'
require 'socket'

require 'faraday-http-cache'
require 'active_support/core_ext/date/calculations'
require 'active_support/core_ext/numeric/time'
require 'yajl'

require 'support/test_app'
require 'support/test_server'

server = TestServer.new

ENV['FARADAY_SERVER'] = server.endpoint
ENV['FARADAY_ADAPTER'] ||= 'net_http'

server.start

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.after(:suite) do
    server.stop
  end
end
