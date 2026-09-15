# frozen_string_literal: true

module Faraday
  class HttpCache < Faraday::Middleware
    # Internal: A class to represent the 'Cache-Control' header options.
    # This implementation is based on 'rack-cache' internals by Ryan Tomayko.
    # It breaks the several directives into keys/values and stores them into
    # a Hash.
    class CacheControl
      # Internal: Initialize a new CacheControl.
      def initialize(header)
        @directives = parse(header.to_s)
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
      # Returns nil if the 'max-age' directive isn't present or has no value.
      def max_age
        integer_directive('max-age')
      end

      # Internal: Gets the 'max-age' directive as an Integer.
      #
      # takes the age header integer value and reduces the max-age and s-maxage
      # if present to account for having to remove static age header when caching responses
      def normalize_max_ages(age)
        if age > 0
          @directives['max-age'] = max_age - age if max_age
          @directives['s-maxage'] = shared_max_age - age if shared_max_age
        end
      end

      # Internal: Gets the 's-maxage' directive as an Integer.
      #
      # Returns nil if the 's-maxage' directive isn't present or has no value.
      def shared_max_age
        integer_directive('s-maxage')
      end
      alias s_maxage shared_max_age

      # Internal: Checks if the 'must-revalidate' directive is present.
      def must_revalidate?
        @directives['must-revalidate']
      end

      # Internal: Checks if the 'proxy-revalidate' directive is present.
      def proxy_revalidate?
        @directives['proxy-revalidate']
      end

      # Internal: Gets the 'stale-while-revalidate' directive as an Integer.
      #
      # Returns nil if the 'stale-while-revalidate' directive isn't present or
      # has no value.
      def stale_while_revalidate
        integer_directive('stale-while-revalidate')
      end

      # Internal: Gets the String representation for the cache directives.
      # Directives are joined by a '=' and then combined into a single String
      # separated by commas. Directives with a 'true' value will omit the '='
      # sign and their value.
      #
      # Returns the Cache Control string.
      def to_s
        booleans = []
        values = []

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

      # Internal: Reads a directive whose value must be an integer.
      # A directive given without a value (a bare 'max-age') is parsed as
      # true; treat it as absent instead of calling to_i on it.
      #
      # Returns the Integer value, or nil.
      def integer_directive(name)
        value = @directives[name]
        value.to_i unless value.nil? || value == true
      end

      # Internal: Parses the Cache Control string to a Hash.
      # Existing whitespace will be removed and the string is split on commas.
      # For each part everything before a '=' will be treated as the key
      # and the exceeding will be treated as the value. If only the key is
      # present then the assigned value will default to true.
      #
      # Examples:
      #   parse("max-age=600")
      #   # => { "max-age" => "600"}
      #
      #   parse("max-age")
      #   # => { "max-age" => true }
      #
      # Returns a Hash.
      def parse(header)
        directives = {}

        header.delete(' ').split(',').each do |part|
          next if part.empty?

          name, value = part.split('=', 2)
          directives[name.downcase] = (value || true) unless name.empty?
        end

        directives
      end
    end
  end
end
