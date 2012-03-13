require 'digest/sha1'
require 'active_support/cache'
require 'active_support/core_ext/hash/keys'

module Faraday
  module HttpCache
    # Internal: A Wrapper around a ActiveSupport::CacheStore to store responses.
    #
    # Examples
    #  # Creates a new Storage using a MemCached backend from ActiveSupport.
    #  Faraday::HttpCache::Storage.new(:mem_cache_store)
    #
    #  # Reuse some other instance of a ActiveSupport::CacheStore object.
    #  Faraday::HttpCache::Storage.new(Rails.cache)
    class Storage
      attr_reader :cache

      # Internal: Instantiates a new Storage object with a cache backend.
      #
      # store - An ActiveSupport::CacheStore identifier to
      # options - The Hash options for the CacheStore backend.
      #
      def initialize(store = nil, options = {})
        @cache = ActiveSupport::Cache.lookup_store(store, options)
      end

      # Internal: Writes a response with a key based on the given request.
      #
      # request - The Hash containing the request information.
      #           :method          - The HTTP Method used for the request.
      #           :url             - The requested URL.
      #           :request_headers - The custom headers for the request.
      # response - The Faraday::HttpCache::Response instance to be stored.
      def write(request, response)
        key = cache_key_for(request)
        value = MultiJson.encode(response.payload)
        cache.write(key, value)
      end

      # Internal: Reads a key based on the given request from the underlying cache.
      #
      # request - The Hash containing the request information.
      #           :method          - The HTTP Method used for the request.
      #           :url             - The requested URL.
      #           :request_headers - The custom headers for the request.
      # klass - The Class to be instantiated with the recovered informations.
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
