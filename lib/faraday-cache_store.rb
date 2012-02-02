require 'faraday'
require 'faraday/cache_store'
require 'faraday/cache_store/version'

Faraday.register_middleware :cache_store => lambda { Faraday::CacheStore::Middleware }