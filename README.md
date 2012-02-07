# Faraday Http Cache
A `Faraday` middleware to handle HTTP caching on your client application, validating expiration headers from previous responses.

## Installation

Add it to your Gemfile:

```ruby
gem 'faraday-http-cache'
```

## Usage and configuration

Just add the `http_cache` middleware to your Faraday stack, as in:

```rails
client = Faraday.new do |builder|
  builder.middleware :http_cache
end
```

The middleware uses the `ActiveSupport::Cache` API to record the responses from the targeted endpoints, and any extra configuration option will be used to setup the cache store.

```ruby
# Connect the middleware to a Memcache instance.
client = Faraday.new do |builder|
  builder.middleware :http_cache, :mem_cache_store, "localhost:11211"
end

# Or use the Rails.cache instance inside your Rails app.
client = Faraday.new do |builder|
  builder.use :http_cache, Rails.cache
end
```

The default store provided by ActiveSupport is the `MemoryStore` one, so it's important to configure a proper one for your production environment.

## License