require 'faraday'
require 'multi_json'

require 'faraday/http_cache/storage'
require 'faraday/http_cache/response'
require 'faraday/http_cache/middleware'

if Faraday.respond_to?(:register_middleware)
  Faraday.register_middleware :http_cache => lambda { Faraday::HttpCache::Middleware }
end