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
          Faraday::Response.new(response)
        else
          response = yield
          @storage.write(request, response.marshal_dump)
          response
        end
      end
    end
  end
end