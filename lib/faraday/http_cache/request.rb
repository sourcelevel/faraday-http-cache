module Faraday
  class HttpCache < Faraday::Middleware
    # Internal: A class to represent a request
    class Request
      class << self
        def from_env(env)
          hash = env.to_hash
          new(method: hash[:method], url: hash[:url], body: hash[:body], headers: hash[:request_headers].dup)
        end
      end

      attr_reader :method, :url, :headers, :body

      def initialize(options)
        @method, @url, @headers, @body = options.values_at(:method, :url, :headers, :body)
      end

      # Internal: Validates if the current request method is valid for caching.
      #
      # Returns true if the method is ':get' or ':head'.
      def cacheable?
        return false if method != :get && method != :head
        return false if cache_control.no_store?
        true
      end

      def no_cache?
        cache_control.no_cache?
      end

      # Internal: Gets the 'CacheControl' object.
      def cache_control
        @cache_control ||= CacheControl.new(headers['Cache-Control'])
      end

      def serializable_hash
        {
          method: @method,
          url: @url,
          headers: @headers,
          body: @body
        }
      end
    end
  end
end
