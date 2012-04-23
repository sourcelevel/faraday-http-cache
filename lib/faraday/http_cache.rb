require 'faraday'
require 'multi_json'

require 'faraday/http_cache/storage'
require 'faraday/http_cache/response'
require 'faraday/http_cache/middleware'

module Faraday
  module HttpCache
  end
end

Faraday.register_middleware :http_cache => lambda { Faraday::HttpCache::Middleware }
