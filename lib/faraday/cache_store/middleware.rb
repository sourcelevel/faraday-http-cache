module Faraday
  module CacheStore
    class Middleware < Faraday::Middleware

      def initialize(app, storage)
        super(app)
        @storage = storage
      end

      def call(env)
        if can_cache?(env[:method])
          fetch(env) { @app.call(env) }
        else
          @app.call(env)
        end
      end

      private
      def can_cache?(method)
        method == :get || method == :head
      end

      def fetch(request)
        response = @storage.read(request)
        if response
          entry = Entry.new(response)
          entry.to_response
        else
          response = yield
          payload = response.marshal_dump
          payload[:timestamp] = Time.now
          @storage.write(request, payload)
          response
        end
      end
    end
  end
end