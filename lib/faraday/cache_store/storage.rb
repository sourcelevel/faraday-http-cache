require 'digest/sha1'
require 'active_support/core_ext/hash/keys'

module Faraday
  module CacheStore
    class Storage

      attr_reader :backend

      def initialize(backend)
        @backend = backend
      end

      def write(request, response)
        key = cache_key_for(request)
        value = MultiJson.encode(response)
        backend.write(key, value)
      end

      def read(request)
        key = cache_key_for(request)
        value = backend.read(key)
        if value
          MultiJson.decode(value).symbolize_keys
        end
      end

      private
      def cache_key_for(object)
        Digest::SHA1.hexdigest(MultiJson.encode(object))
      end
    end
  end
end