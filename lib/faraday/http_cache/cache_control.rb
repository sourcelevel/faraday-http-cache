module Faraday
  class HttpCache < Faraday::Middleware
    # Internal: a class to represent the 'Cache-Control' header options.
    # This implementation is based on 'rack-cache' internals by Ryan Tomayko.
    # It breaks the several directives into keys/values and stores them into
    # a Hash.
    class CacheControl

      # Internal: Initialize a new CacheControl.
      def initialize(string)
        @directives = {}
        parse(string)
      end

      # Internal: Checks if the 'public' directive is present.
      def public?
        @directives['public']
      end

      # Internal: Checks if the 'private' directive is present.
      def private?
        @directives['private']
      end

      # Internal: Checks if the 'no-cache' directive is present.
      def no_cache?
        @directives['no-cache']
      end

      # Internal: Checks if the 'no-store' directive is present.
      def no_store?
        @directives['no-store']
      end

      # Internal: Gets the 'max-age' directive as an Integer.
      #
      # Returns nil if the 'max-age' directive isn't present.
      def max_age
        @directives['max-age'].to_i if @directives.key?('max-age')
      end

      # Internal: Gets the 's-maxage' directive as an Integer.
      #
      # Returns nil if the 's-maxage' directive isn't present.
      def shared_max_age
        @directives['s-maxage'].to_i if @directives.key?('s-maxage')
      end
      alias_method :s_maxage, :shared_max_age

      # Internal: Checks if the 'must-revalidate' directive is present.
      def must_revalidate?
        @directives['must-revalidate']
      end

      # Internal: Checks if the 'proxy-revalidate' directive is present.
      def proxy_revalidate?
        @directives['proxy-revalidate']
      end

      # Internal: Gets the String representation for the cache directives.
      # Directives are joined by a '=' and then combined into a single String
      # separated by commas. Directives with a 'true' value will omit the '='
      # sign and their value.
      #
      # Returns the Cache Control string.
      def to_s
        booleans, values = [], []

        @directives.each do |key, value|
          if value == true
            booleans << key
          elsif value
            values << "#{key}=#{value}"
          end
        end

        (booleans.sort + values.sort).join(', ')
      end

      private

      # Internal: Parses the Cache Control string into the directives Hash.
      # Existing whitespaces are removed, and the string is splited on commas.
      # For each segment, everything before a '=' will be treated as the key
      # and the excedding will be treated as the value. If only the key is
      # present the assigned value will defaults to true.
      #
      # Examples:
      #   parse("max-age=600")
      #   @directives
      #    # => { "max-age" => "600"}
      #
      #   parse("max-age")
      #   @directives
      #    # => { "max-age" => true }
      #
      # Returns nothing.
      def parse(string)
        string = string.to_s

        return if string.empty?

        string.delete(' ').split(',').each do |part|
          next if part.empty?

          name, value = part.split('=', 2)
          @directives[name.downcase] = (value || true) unless name.empty?
        end
      end
    end
  end
end
