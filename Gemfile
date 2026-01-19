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

gem 'activesupport',      '>= 7.0'
gem 'em-http-request',    '>= 1.1'
gem 'rake',               '>= 13.0'
gem 'rspec',              '>= 3.1'
gem 'sinatra',            '>= 3.0'
gem 'webrick'

eval_gemfile 'gemfiles/rubocop.gemfile'
