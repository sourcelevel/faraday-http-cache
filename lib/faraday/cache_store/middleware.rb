module Faraday
  module CacheStore
    class Middleware < Faraday::Middleware

      def initialize(app, storage)
        super(app)
        @storage = storage
      end

      def call(env)
        fetch(env) { @app.call(env) }
      end

      private
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