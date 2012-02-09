require 'time'
require 'faraday/http_cache/cache_control'

module Faraday
  module HttpCache
    # Response object that calculates the cache status based
    # on the stored headers and the `Cache-Control` directives.
    #
    # It wraps the general response Hash from `Faraday` responses and
    # recreates an instance of `Faraday::Response` if necessary.
    class Response
      # Cacheable status code:
      #   `OK`, `Non-Authoritative Information`, `Multiple Choices`,
      #   `Moved Permanently`, `Found`, 'Not Found` and `Gone`.
      CACHEABLE_STATUS_CODES = [200, 203, 300, 301, 302, 404, 410]

      attr_reader :payload

      def initialize(payload = {})
        @now = Time.now
        @payload = payload
        wrap_headers!
        headers['Date'] ||= @now.httpdate
      end

      def fresh?
        ttl > 0
      end

      def not_modified?
        @payload[:status] == 304
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

      # The `s-maxage` has precedence over the `max-age`
      # directive. If both are missing, calculates it based
      # on the `Expires` and `Date` headers.
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

      def wrap_headers!
        headers = @payload[:response_headers]

        @payload[:response_headers] = Faraday::Utils::Headers.new
        @payload[:response_headers].update(headers) if headers
      end

      def headers
        @payload[:response_headers]
      end
    end
  end
end