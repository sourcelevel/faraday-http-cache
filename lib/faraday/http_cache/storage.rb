require 'json'
require 'digest/sha1'

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
      # Internal: Initialize a new Storage object with a cache backend.
      #
      # options - Storage options (default: {}).
      #           :logger        - A Logger object to be used to emit warnings.
      #           :store         - An cache store object that should
      #                            respond to 'dump' and 'load'.
      #           :serializer    - A serializer object that should
      #                            respond to 'dump' and 'load'.
      #           :store_options - An array containg the options for
      #                            the cache store.
      def initialize(options = {})
        @cache = options[:store] || MemoryStore.new
        @serializer = options[:serializer] || JSON
        @logger = options[:logger]
        if @cache.is_a? Symbol
          @cache = lookup_store(@cache, options[:store_options])
        end
        assert_valid_store!
        notify_memory_store_usage
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
        @cache.write(key, value)
      end

      # Internal: Reads a key based on the given request from the underlying cache.
      #
      # request - The Hash containing the request information.
      #           :method          - The HTTP Method used for the request.
      #           :url             - The requested URL.
      #           :request_headers - The custom headers for the request.
      # klass - The Class to be instantiated with the recovered informations.
      def read(request, klass = Faraday::HttpCache::Response)
        cache_key = cache_key_for(request)
        found = @cache.read(cache_key)

        if found
          payload = @serializer.load(found).inject({}) do |hash, (key,value)|
            hash.update(key.to_sym => value)
          end

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
        cache_keys = request.inject([]) do |parts, (key, value)|
          parts << [key.to_s, value]
        end

        Digest::SHA1.hexdigest(@serializer.dump(cache_keys.sort))
      end

      # Internal: Logs a warning when the 'cache' implementation
      # isn't suitable for production use.
      #
      # Returns nothing.
      def notify_memory_store_usage
        return if @logger.nil?

        kind = @cache.class.name.split('::').last.sub('Store', '').downcase
        if kind == 'memory'
          @logger.warn 'HTTP Cache: using a MemoryStore is not advised as the cache might not be persisted across multiple processes or connection instances.'
        end
      end

      # Internal: Creates a cache store from 'ActiveSupport' a set of options.
      #
      # store   - A 'Symbol' with the store name.
      # options - Additional options for the cache store.
      #
      # Returns a 'ActiveSupport::Cache' store.
      def lookup_store(store, options)
        if @logger
          @logger.warn "Passing a Symbol as the 'store' is deprecated, please pass the cache store instead."
        end

        require 'active_support/cache'
        ActiveSupport::Cache.lookup_store(store, options)
      end

      # Internal: Checks if the given cache object supports the
      # expect API ('read' and 'write').
      #
      # Raises an 'ArgumentError'.
      #
      # Returns nothing.
      def assert_valid_store!
        unless @cache.respond_to?(:read) && @cache.respond_to?(:write)
          raise ArgumentError.new("#{@cache.inspect} is not a valid cache store as it does not responds to 'read' and 'write'.")
        end
      end
    end

    # Internal: A Hash based store to be used by the 'Storage' class
    # when a 'store' is not provided for the middleware setup.
    class MemoryStore
      def initialize
        @cache = {}
      end

      def read(key)
        @cache[key]
      end

      def write(key, value)
        @cache[key] = value
      end
    end
  end
end
