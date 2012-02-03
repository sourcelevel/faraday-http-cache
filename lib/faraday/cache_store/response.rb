require 'faraday/cache_store/cache_control'

module Faraday
  module CacheStore
    class Response

      def initialize(payload = {})
        @now = Time.now
        @payload = payload
        headers['Date'] ||= @now.httpdate
      end

      def fresh?
        ttl > 0
      end

      def age
        (headers['Age'] || (@now - date)).to_i
      end

      def to_response
        Faraday::Response.new(@payload)
      end

      def ttl
        max_age - age
      end

      def date
        Time.httpdate(headers['Date'])
      end

      def max_age
        cache_control.shared_max_age ||
          cache_control.max_age ||
          (expires && (expires - date))
      end

      private

      def expires
        headers['Expires'] && Time.httpdate(headers['Expires'])
      end

      def cache_control
        @cache_control ||= CacheControl.new(headers['Cache-Control'])
      end

      def headers
        @payload[:response_headers] ||= {}
      end
    end
  end
end