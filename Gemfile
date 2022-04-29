source 'https://rubygems.org'

gemspec

install_if -> { ENV['FARADAY_VERSION'] } do
  gem 'faraday', ENV['FARADAY_VERSION']
end

if /\D*([\d.]*)/.match(ENV.fetch('FARADAY_VERSION', ''))[1].start_with?('0')
  gem 'faraday_middleware'
elsif ENV['FARADAY_ADAPTER'] == 'em_http'
  gem 'faraday-em_http'
end

gem 'em-http-request',    '~> 1.1'
gem 'rspec',              '~> 3.1'
gem 'rake',               '~> 13.0'
gem 'activesupport',      '>= 5.0'
gem 'sinatra',            '~> 2.0'
