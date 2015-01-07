module Faraday
  class HttpCache < Faraday::Middleware
    # Internal: A class to represent a request
    class Request

      class << self
        def from_env(env)
          hash = env.to_hash
          new(method: hash[:method], url: hash[:url], headers: hash[:request_headers].dup)
        end
      end

      attr_reader :method, :url, :headers

      def initialize(options)
        @method, @url, @headers = options[:method], options[:url], options[:headers]
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

      def cache_key
        digest = Digest::SHA1.new
        digest.update 'method'
        digest.update method.to_s
        digest.update 'request_headers'
        headers.keys.sort.each do |key|
          digest.update key.to_s
          digest.update headers[key].to_s
        end
        digest.update 'url'
        digest.update url.to_s

        digest.to_s
      end

    end
  end
end
