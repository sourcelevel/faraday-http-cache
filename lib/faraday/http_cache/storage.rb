require 'digest/sha1'
require 'active_support/cache'
require 'active_support/core_ext/hash/keys'

module Faraday
  class HttpCache < Faraday::Middleware
    # Internal: A Wrapper around a ActiveSupport::CacheStore to store responses.
    #
    # Examples
    #   # Creates a new Storage using a MemCached backend from ActiveSupport.
    #   Faraday::HttpCache::Storage.new(:mem_cache_store)
    #
    #   # Reuse some other instance of a ActiveSupport::CacheStore object.
    #   Faraday::HttpCache::Storage.new(Rails.cache)
    #
    #   # Creates a new Storage using Marshal for serialization.
    #   Faraday::HttpCache::Storage.new(:memory_store, serializer: Marshal)
    class Storage
      attr_reader :cache, :serializer

      # Internal: Initialize a new Storage object with a cache backend.
      #
      # store - An ActiveSupport::CacheStore identifier (default: nil).
      # options - The Hash options for the CacheStore backend (default: {}).
      #   :serializer - duck type with #load and #dump
      def initialize(store = nil, options = {})
        @serializer = MultiJson
        if options.is_a? Hash
          @serializer = options.delete(:serializer) || MultiJson
        end
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
        value = serializer.dump(response.serializable_hash)
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
          payload = serializer.load(value).symbolize_keys
          klass.new(payload)
        end
      end

      private

      # Internal: Generates a String key for a given request object.
      # The request object is folded into a sorted Array (since we can't count
      # on hashes order on Ruby 1.8), encoded as JSON and digested as a `SHA1`
      # string.
      #
      # Returns the encoded String.
      def cache_key_for(request)
        array = request.stringify_keys.to_a.sort
        Digest::SHA1.hexdigest(MultiJson.dump(array))
      end
    end
  end
end
