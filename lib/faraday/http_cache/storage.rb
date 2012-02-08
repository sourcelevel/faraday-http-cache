require 'digest/sha1'
require 'active_support/cache'
require 'active_support/core_ext/hash/keys'

module Faraday
  module HttpCache
    # Storage class that wraps the acess to a `ActiveSupport::Cache::Store` instance
    # that holds the stored responses for previous requests.
    #
    # Request hashes (made of :method, :url and :request_headers keys) will be
    # encoded as a SHA1 digest of their JSON representation and paired with
    # their cached responses.
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

      def read(request, klass = Faraday::HttpCache::Response)
        key = cache_key_for(request)
        value = cache.read(key)
        if value
          payload = MultiJson.decode(value).symbolize_keys
          klass.new(payload)
        end
      end

      private
      def cache_key_for(object)
        array = object.stringify_keys.to_a.sort
        Digest::SHA1.hexdigest(MultiJson.encode(array))
      end
    end
  end
end