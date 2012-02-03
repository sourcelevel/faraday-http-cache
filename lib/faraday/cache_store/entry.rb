require 'faraday/cache_store/cache_control'

module Faraday
  module CacheStore
    class Entry

      def initialize(payload)
        @now = Time.now
        @payload = payload
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
        date_header = headers['Date']
        if date_header
          Time.httpdate(headers['Date'])
        else
          headers['Date'] = @now.httpdate
          @now
        end
      end

      private
      def max_age
        cache_control.max_age
      end

      def cache_control
        @cache_control ||= CacheControl.new(headers['Cache-Control'])
      end

      def headers
        @payload[:response_headers]
      end
    end
  end
end