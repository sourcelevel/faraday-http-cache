require 'json'
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
      attr_reader :cache

      # Internal: Initialize a new Storage object with a cache backend.
      #
      # options      - Storage options (default: {}).
      #                :logger        - A Logger object to be used to emit warnings.
      #                :store         - An ActiveSupport::CacheStore identifier.
      #                :serializer    - A serializer object that should
      #                                 respond to 'dump' and 'load'.
      #                :store_options - An array containg the options for
      #                                 the cache store.
      def initialize(options = {})
        store = options[:store]
        @serializer = options[:serializer] || JSON

        @cache = ActiveSupport::Cache.lookup_store(store, options[:store_options])
        notify_memory_store_usage(options[:logger])
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
        value = @serializer.dump(response.serializable_hash)
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
          payload = @serializer.load(value).symbolize_keys
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
        Digest::SHA1.hexdigest(cache_key_prefix_for(request)) + Digest::SHA1.hexdigest(@serializer.dump(array))
      end

      def cache_key_prefix_for(request)
        prefix = [path(request), authorization(request)].join("_") + "_"
      end

      def path(request)
        request[:url].path
      end

      def authorization(request)
        if request[:request_headers].key? "Authorization"
          request[:request_headers]["Authorization"].gsub(/token /, '')
        end
      end

      # Internal: Logs a warning when the 'cache' implementation
      # isn't suitable for production use.
      #
      # Returns nothing.
      def notify_memory_store_usage(logger)
        return if logger.nil?

        kind = cache.class.name.split('::').last.sub('Store', '').downcase
        if kind == 'memory'
          logger.warn 'HTTP Cache: using a MemoryStore is not advised as the cache might not be persisted across multiple processes or connection instances.'
        end
      end
    end
  end
end
