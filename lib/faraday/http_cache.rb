require 'faraday'
require 'multi_json'

require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/hash/slice'

require 'faraday/http_cache/storage'
require 'faraday/http_cache/response'

module Faraday
  # Public: The middleware responsible for caching and serving responses.
  # The middleware use the provided configuration options to establish a
  # 'Faraday::HttpCache::Storage' to cache responses retrieved by the stack
  # adapter. If a stored response can be served again for a subsequent
  # request, the middleware will return the response instead of issuing a new
  # request to it's server. This middleware should be the last attached handler
  # to your stack, so it will be closest to the inner app, avoiding issues
  # with other middlewares on your stack.
  #
  # Examples:
  #
  #   # Using the middleware with a simple client:
  #   client = Faraday.new do |builder|
  #     builder.user :http_cache
  #     builder.adapter Faraday.default_adapter
  #   end
  #
  #   # Attach a Logger to the middleware.
  #   client = Faraday.new do |builder|
  #     builder.use :http_cache, :logger => my_logger_instance
  #     builder.adapter Faraday.default_adapter
  #   end
  #
  #   # Provide an existing CacheStore (for instance, from a Rails app)
  #   client = Faraday.new do |builder|
  #     builder.use :http_cache, Rails.cache
  #   end
  class HttpCache < Faraday::Middleware

    # Public: Initializes a new HttpCache middleware.
    #
    # app - the next endpoint on the 'Faraday' stack.
    # arguments - aditional options to setup the logger and the storage.
    #
    # Examples:
    #
    #   # Initialize the middleware with a logger.
    #   Faraday::HttpCache.new(app, :logger => my_logger)
    #
    #   # Initialize the middleware with a FileStore at the 'tmp' dir.
    #   Faraday::HttpCache.new(app, :file_store, 'tmp')
    def initialize(app, *arguments)
      super(app)

      if arguments.last.is_a? Hash
        options = arguments.pop
        @logger = options.delete(:logger)
      else
        options = arguments
      end

      store = arguments.shift

      @storage = Storage.new(store, options)
    end

    # Public: Process the request into a duplicate of this instance to
    # ensure that the internal state is preserved.
    def call(env)
      dup.call!(env)
    end

    # Internal: Process the stack request to try to serve a cache response.
    # On a cacheable request, the middleware will attempt to locate a
    # valid stored response to serve. On a cache miss, the middleware will
    # forward the request and try to store the response for future requests.
    # If the request can't be cached, the request will be delegated directly
    # to the underlying app and does nothing to the response.
    # The processed steps will be recorded to be logged once the whole
    # process is finished.
    #
    # Returns a 'Faraday::Response' instance.
    def call!(env)
      @trace = []
      @request = create_request(env)

      response = nil

      if can_cache?(@request[:method])
        response = process(env)
      else
        trace :unacceptable
        response = @app.call(env)
      end

      response.on_complete do
        log_request
      end
    end

    private
    # Internal: Validates if the current request method is valid for caching.
    #
    # Returns true if the method is ':get' or ':head'.
    def can_cache?(method)
      method == :get || method == :head
    end

    # Internal: Tries to located a valid response or forwards the call to the stack.
    # * If no entry is present on the storage, the 'fetch' method will forward
    # the call to the remaining stack and return the new response.
    # * If a fresh response is found, the middleware will abort the remaining
    # stack calls and return the stored response back to the client.
    # * If a response is found but isn't fresh anymore, the middleware will
    # revalidate the response back to the server.
    #
    # env - the environment 'Hash' provided from the 'Faraday' stack.
    #
    # Returns the 'Faraday::Response' instance to be served.
    def process(env)
      entry = @storage.read(@request)

      return fetch(env) if entry.nil?

      if entry.fresh?
        response = entry.to_response(env)
        trace :fresh
      else
        response = validate(entry, env)
      end

      response
    end

    # Internal: Tries to validated a stored entry back to it's origin server
    # using the 'If-Modified-Since' and 'If-None-Match' headers with the
    # existing 'Last-Modified' and 'ETag' headers. If the new response
    # is marked as 'Not Modified', the previous stored response will be used
    # and forwarded against the Faraday stack. Otherwise, the freshly new
    # response will be stored (replacing the old one) and used.
    #
    # entry - a stale 'Faraday::HttpCache::Response' retrieved from the cache.
    # env - the environment 'Hash' to perform the request.
    #
    # Returns the 'Faraday::HttpCache::Response' to be forwarded into the stack.
    def validate(entry, env)
      headers = env[:request_headers]
      headers['If-Modified-Since'] = entry.last_modified if entry.last_modified
      headers['If-None-Match'] = entry.etag if entry.etag

      @app.call(env).on_complete do |env|
        response = Response.new(env)
        if response.not_modified?
          trace :valid
          env.update(entry.payload)
          response = entry
        end
        store(response)
      end
    end

    # Internal: Records a traced action to be used by the logger once the
    # request/response phase is finished.
    #
    # operation - the name of the performed action, a String or Symbol.
    #
    # Returns nothing.
    def trace(operation)
      @trace << operation
    end

    # Internal: Stores the response into the storage.
    # If the response isn't cacheable, a trace action 'invalid' will be
    # recorded for logging purposes.
    #
    # response - a 'Faraday::HttpCache::Response' instance to be stored.
    #
    # Returns nothing.
    def store(response)
      if response.cacheable?
        trace :store
        @storage.write(@request, response)
      else
        trace :invalid
      end
    end

    # Internal: Fetches the response from the Faraday stack and stores it.
    #
    # env - the environment 'Hash' from the Faraday stack.
    #
    # Returns the fresh 'Faraday::Response' instance.
    def fetch(env)
      trace :miss
      @app.call(env).on_complete do |env|
        response = Response.new(create_response(env))
        store(response)
      end
    end

    # Internal: Creates a new 'Hash' containing the response information.
    #
    # env - the environment 'Hash' from the Faraday stack.
    #
    # Returns a 'Hash' containing the ':status', ':body' and 'response_headers'
    # entries.
    def create_response(env)
      env.to_hash.symbolize_keys.slice(:status, :body, :response_headers)
    end

    # Internal: Creates a new 'Hash' containing the request information.
    #
    # env - the environment 'Hash' from the Faraday stack.
    #
    # Returns a 'Hash' containing the ':method', ':url' and 'request_headers'
    # entries.
    def create_request(env)
      request = env.to_hash.symbolize_keys.slice(:method, :url, :request_headers)
      request[:request_headers] = request[:request_headers].dup
      request
    end

    # Internal: Logs the trace info about the incoming request
    # and how the middleware handled it.
    # This method does nothing if theresn't a logger present.
    #
    # Returns nothing.
    def log_request
      return unless @logger

      method = @request[:method].to_s.upcase
      path = @request[:url].path
      line = "HTTP Cache: [#{method} #{path}] #{@trace.join(', ')}"
      @logger.debug(line)
    end
  end
end

if Faraday.respond_to?(:register_middleware)
  Faraday.register_middleware :http_cache => Faraday::HttpCache
else
  Faraday::Request.register_middleware :http_cache => Faraday::HttpCache
end
