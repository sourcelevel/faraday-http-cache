require 'time'
require 'faraday/http_cache/cache_control'

module Faraday
  module HttpCache
    # Response object that calculates the cache status based
    # on the stored headers and the 'Cache-Control' directives.
    #
    # It wraps the general response Hash from 'Faraday' responses and
    # recreates an instance of 'Faraday::Response' if necessary.
    class Response
      # Internal: List of status codes that can be cached:
      #           'OK', 'Non-Authoritative Information', 'Multiple Choices',
      #           'Moved Permanently', 'Found', 'Not Found' and 'Gone'.
      CACHEABLE_STATUS_CODES = [200, 203, 300, 301, 302, 404, 410]

      # Internal: Gets the actual response Hash (status, headers and body).
      attr_reader :payload

      # Internal: Gets the 'Last-Modified' header from the headers Hash.
      attr_reader :last_modified

      # Internal: Gets the 'ETag' header from the headers Hash.
      attr_reader :etag

      def initialize(payload = {})
        @now = Time.now
        @payload = payload
        wrap_headers!
        headers['Date'] ||= @now.httpdate

        @last_modified = headers['Last-Modified']
        @etag = headers['ETag']
      end

      # Internal: Checks the response freshness based on expiration headers.
      # The calculated 'ttl' should be present and bigger than 0.
      #
      # Returns true if the response is fresh, otherwise false.
      def fresh?
        ttl && ttl > 0
      end

      # Internal: Checks if the Response returned a 'Not Modified' status.
      #
      # Returns true if the response status code is 304.
      def not_modified?
        @payload[:status] == 304
      end

      # Internal: Checks if the response can be cached by the client.
      #  This is validated by the 'Cache-Control' directives, the response
      #  status code and it's freshness or validation status.
      #
      # Returns false if the 'Cache-Control' says that we can't store the
      #   response, or if isn't fresh or it can't be revalidated with the origin
      #   server. Otherwise, returns true.
      def cacheable?
        return false if cache_control.private? || cache_control.no_store?

        cacheable_status_code? && (validateable? || fresh?)
      end

      # Internal: Gets the response age in seconds.
      #
      # Returns the 'Age' header if present, or subtracts the response 'date'
      #  from the current time.
      def age
        (headers['Age'] || (@now - date)).to_i
      end


      # Internal: Calculates the 'Time to live' left on the Response.
      #
      # Returns the remaining seconds for the response, or nil the 'max_age'
      #   isn't present.
      def ttl
        max_age - age if max_age
      end

      # Internal: Parses the 'Date' header back into a Time instance.
      def date
        Time.httpdate(headers['Date'])
      end

      # Internal: Gets the response max age.
      #  The max age is extracted from one of the following:
      #  - The shared max age directive from the 'Cache-Control' header;
      #  - The max age directive from the 'Cache-Control' header;
      #  - The difference between the 'Expires' header and the response
      #    date.
      #
      # Returns the max age value in seconds or nil if all options above fails.
      def max_age
        cache_control.shared_max_age ||
          cache_control.max_age ||
          (expires && (expires - date))
      end

      # Internal: Creates a new 'Faraday::Response'.
      # Returns a new instance of a 'Faraday::Response' with the payload.
      def to_response
        Faraday::Response.new(@payload)
      end

      private

      def validateable?
        headers.key?('Last-Modified') || headers.key?('ETag')
      end

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
