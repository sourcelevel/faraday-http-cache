require 'forwardable'

module Faraday
  module HttpCache
    # A parser for the `Cache-Control` header, based on the implementation
    # done in the rack-cache gem by Ryan Tomayko.
    class CacheControl
      extend Forwardable

      def_delegators :@directives, :[], :[]=, :include?

      def initialize(string = nil)
        @directives = {}
        parse(string)
      end

      def public?
        @directives['public']
      end

      def private?
        @directives['private']
      end

      def no_cache?
        @directives['no-cache']
      end

      def no_store?
        @directives['no-store']
      end

      def max_age
        @directives['max-age'].to_i if @directives.key?('max-age')
      end

      def shared_max_age
        @directives['s-maxage'].to_i if @directives.key?('s-maxage')
      end
      alias_method :s_maxage, :shared_max_age

      def must_revalidate?
        @directives['must-revalidate']
      end

      def proxy_revalidate?
        @directives['proxy-revalidate']
      end

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
