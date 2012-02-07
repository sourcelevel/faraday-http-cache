require 'active_support/core_ext/hash/slice'

module Faraday
  module HttpCache
    class Middleware < Faraday::Middleware

      def initialize(app, store = nil, options = {})
        super(app)
        @storage = Storage.new(store, options)
      end

      def call(env)
        request = env.slice(:method, :url, :request_headers)
        if can_cache?(request[:method])
          fetch(request) { @app.call(env) }
        else
          @app.call(env)
        end
      end

      private
      def can_cache?(method)
        method == :get || method == :head
      end

      def fetch(request)
        entry = @storage.read(request)

        if entry && entry.fresh?
          response = entry
        else
          response = Response.new(yield.marshal_dump)
        end

        if response.cacheable?
          @storage.write(request, response)
        end
        response.to_response
      end
    end
  end
end