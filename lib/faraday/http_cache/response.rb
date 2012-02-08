require 'time'
require 'faraday/http_cache/cache_control'

module Faraday
  module HttpCache
    class Response
      CACHEABLE_STATUS_CODES = [200, 203, 300, 301, 302, 404, 410]

      attr_reader :payload

      def initialize(payload = {})
        @now = Time.now
        @payload = payload
        headers['Date'] ||= @now.httpdate
      end

      def fresh?
        ttl > 0
      end

      def cacheable?
        return false if cache_control.private? || cache_control.no_store?
        cacheable_status_code? && fresh?
      end

      def age
        (headers['Age'] || (@now - date)).to_i
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

      def to_response
        Faraday::Response.new(@payload)
      end

      private

      def cacheable_status_code?
        CACHEABLE_STATUS_CODES.include?(@payload[:status])
      end

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