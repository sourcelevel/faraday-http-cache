require 'faraday/cache_store/cache_control'

module Faraday
  module CacheStore
    class Entry

      def initialize(payload)
        @payload = payload
      end

      def to_response
        Faraday::Response.new(@payload)
      end
    end
  end
end