# Faraday Http Cache
a [Faraday](https://github.com/technoweenie/faraday) middleware that respects HTTP cache, by validating expiration headers from stored responses.

## Installation

Add it to your Gemfile:

```ruby
gem 'faraday-http-cache'
```

## Usage and configuration

If you're using Faraday 0.8 or higher, you can use the new shortcut using a symbol:

```ruby
client = Faraday.new do |builder|
  builder.use :http_cache
end
```

For previous versions of Faraday, the usage is:

```ruby
client = Faraday.new do |builder|
  builder.use Faraday::HttpCache::Middleware
end
```

The middleware uses the `ActiveSupport::Cache` API to record the responses from the targeted endpoints, and any extra configuration option will be used to setup the cache store.

```ruby
# Connect the middleware to a Memcache instance.
client = Faraday.new do |builder|
  builder.use :http_cache, :mem_cache_store, "localhost:11211"
end

# Or use the Rails.cache instance inside your Rails app.
client = Faraday.new do |builder|
  builder.use :http_cache, Rails.cache
end
```

The default store provided by ActiveSupport is the `MemoryStore` one, so it's important to configure a proper one for your production environment.

## See it live

You can clone this repository, install it's dependencies with Bundler (run `bundle install`) and execute the `examples/twitter.rb` file to see a sample of the middleware usage - it's issuing requests to the Twitter API and caching them, so the Rate limit isn't consumed on every request by the client object.

## License