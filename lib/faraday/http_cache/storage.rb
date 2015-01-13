require 'json'
require 'digest/sha1'

module Faraday
  class HttpCache < Faraday::Middleware
    # Internal: A wrapper around an ActiveSupport::CacheStore to store responses.
    #
    # Examples
    #
    #   # Creates a new Storage using a MemCached backend from ActiveSupport.
    #   Faraday::HttpCache::Storage.new(:mem_cache_store)
    #
    #   # Reuse some other instance of an ActiveSupport::Cache::Store object.
    #   Faraday::HttpCache::Storage.new(Rails.cache)
    #
    #   # Creates a new Storage using Marshal for serialization.
    #   Faraday::HttpCache::Storage.new(:memory_store, serializer: Marshal)
    class Storage
      # Public: Gets the underlying cache store object.
      attr_reader :cache

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
      end

      # Internal: Store a response inside the cache.
      #
      # request  - A Faraday::HttpCache::::Request instance of the executed HTTP
      #            request.
      # response - The Faraday::HttpCache::Response instance to be stored.
      #
      # Returns nothing.
      def write(request, response)
        key = cache_key_for(request)
        entry = serialize_entry(request.serializable_hash, response.serializable_hash)

        entries = cache.read(key) || []

        entries.reject! do |(cached_request, cached_response)|
          response_matches?(request, deserialize_object(cached_request), deserialize_object(cached_response))
        end

        entries << entry

        cache.write(key, entries)
      rescue Encoding::UndefinedConversionError => e
        warn "Response could not be serialized: #{e.message}. Try using Marshal to serialize."
        raise e
      end

      # Internal: Attempt to retrieve an stored response that suits the incoming
      # HTTP request.
      #
      # request  - A Faraday::HttpCache::::Request instance of the incoming HTTP
      #            request.
      # klass    - The Class to be instantiated with the stored response.
      #
      # Returns an instance of 'klass'.
      def read(request, klass = Faraday::HttpCache::Response)
        cache_key = cache_key_for(request)
        entries = cache.read(cache_key)
        response = lookup_response(request, entries)

        if response
          klass.new(response)
        end
      end

      private

      # Internal: Retrieve a response Hash from the list of entries that match
      # the given request.
      #
      # request  - A Faraday::HttpCache::::Request instance of the incoming HTTP
      #            request.
      # entries  - An Array of pairs of Hashes (request, response).
      #
      # Returns a Hash or nil.
      def lookup_response(request, entries)
        if entries
          entries = entries.map { |entry| deserialize_entry(*entry) }
          _, response = entries.find { |req, res| response_matches?(request, req, res) }
          response
        end
      end

      # Internal: Check if a cached response and request matches the given
      # request.
      #
      # request         - A Faraday::HttpCache::::Request instance of the
      #                   current HTTP request.
      # cached_request  - The Hash of the request that was cached.
      # cached_response - The Hash of the response that was cached.
      #
      # Returns true or false.
      def response_matches?(request, cached_request, cached_response)
        request.method.to_s == cached_request[:method]
      end

      def serialize_entry(*objects)
        objects.map { |object| serialize_object(object) }
      end

      def serialize_object(object)
        @serializer.dump(object)
      end

      def deserialize_entry(*objects)
        objects.map { |object| deserialize_object(object) }
      end

      def deserialize_object(object)
        @serializer.load(object).each_with_object({}) do |(key, value), hash|
          hash[key.to_sym] = value
        end
      end

      # Internal: Computes the cache key for a specific request, taking in
      # account the current serializer to avoid cross serialization issues.
      #
      # request - The Faraday::HttpCache::Request instance.
      #
      # Returns a String.
      def cache_key_for(request)
        prefix = (@serializer.is_a?(Module) ? @serializer : @serializer.class).name
        Digest::SHA1.hexdigest("#{prefix}#{request.url}")
      end

      # Internal: Creates a cache store from 'ActiveSupport' with a set of options.
      #
      # store   - A 'Symbol' with the store name.
      # options - Additional options for the cache store.
      #
      # Returns an 'ActiveSupport::Cache' store.
      def lookup_store(store, options)
        warn "Passing a Symbol as the 'store' is deprecated, please pass the cache store instead."

        begin
          require 'active_support/cache'
          ActiveSupport::Cache.lookup_store(store, options)
        rescue LoadError => e
          puts "You're missing the 'activesupport' gem. Add it to your Gemfile, bundle it and try again"
          raise e
        end
      end

      # Internal: Checks if the given cache object supports the
      # expect API ('read' and 'write').
      #
      # Raises an 'ArgumentError'.
      #
      # Returns nothing.
      def assert_valid_store!
        unless cache.respond_to?(:read) && cache.respond_to?(:write)
          raise ArgumentError.new("#{cache.inspect} is not a valid cache store as it does not responds to 'read' and 'write'.")
        end
      end

      def warn(message)
        @logger.warn(message) if @logger
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
