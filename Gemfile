source 'https://rubygems.org'

gemspec

install_if -> { ENV['FARADAY_VERSION'] } do
  gem 'faraday', ENV['FARADAY_VERSION']
end

faraday_version = /\D*([\d.]*)/.match(ENV.fetch('FARADAY_VERSION', ''))[1]

if faraday_version.start_with?('0')
  gem 'faraday_middleware'
elsif ENV['FARADAY_ADAPTER'] == 'em_http'
  gem 'faraday-em_http'
end

# Faraday 1's JSON response middleware passes its options to JSON.parse as a
# positional hash, which json 3 no longer accepts.
gem 'json', '< 3' if faraday_version.start_with?('1')

gem 'activesupport',      '>= 7.0'
gem 'em-http-request',    '>= 1.1'
gem 'rackup'
gem 'rake',               '>= 13.0'
gem 'rspec',              '>= 3.1'
gem 'sinatra',            '>= 3.0'
gem 'webrick'

eval_gemfile 'gemfiles/rubocop.gemfile'
