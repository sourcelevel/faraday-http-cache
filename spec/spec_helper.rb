require 'uri'

require 'faraday-http-cache'
require 'active_support/core_ext/date/calculations'
require 'active_support/core_ext/numeric/time'
require 'yajl'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
end
