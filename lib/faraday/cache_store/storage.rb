require 'digest/sha1'
require 'active_support/cache'
require 'active_support/core_ext/hash/keys'

module Faraday
  module CacheStore
    class Storage

      attr_reader :cache

      def initialize(store = nil, options = {})
        @cache = ActiveSupport::Cache.lookup_store(store, options)
      end

      def write(request, response)
        key = cache_key_for(request)
        value = MultiJson.encode(response.payload)
        cache.write(key, value)
      end

      def read(request, klass = Faraday::CacheStore::Response)
        key = cache_key_for(request)
        value = cache.read(key)
        if value
          payload = MultiJson.decode(value).symbolize_keys
          klass.new(payload)
        end
      end

      private
      def cache_key_for(object)
        Digest::SHA1.hexdigest(MultiJson.encode(object))
      end
    end
  end
end