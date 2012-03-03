# Faraday Http Cache
a [Faraday](https://github.com/technoweenie/faraday) middleware that respects HTTP cache,
by checking expiration and validation of the stored responses.

## Installation

Add it to your Gemfile:

```ruby
gem 'faraday-http-cache', :require => 'faraday_http_cache'
```

## Usage and configuration

If you're using Faraday 0.8 or higher, you can use the new shortcut using a symbol:

```ruby
client = Faraday.new do |builder|
  builder.use :http_cache
  builder.adapter Faraday.default_adapter
end
```

For previous versions of Faraday, the usage is:

```ruby
client = Faraday.new do |builder|
  builder.use Faraday::HttpCache::Middleware
  builder.adapter Faraday.default_adapter
end
```

The middleware uses the `ActiveSupport::Cache` API to record the responses from the targeted
endpoints, and any extra configuration option will be used to setup the cache store.

```ruby
# Connect the middleware to a Memcache instance.
client = Faraday.new do |builder|
  builder.use :http_cache, :mem_cache_store, "localhost:11211"
  builder.adapter Faraday.default_adapter
end

# Or use the Rails.cache instance inside your Rails app.
client = Faraday.new do |builder|
  builder.use :http_cache, Rails.cache
  builder.adapter Faraday.default_adapter
end
```

The default store provided by ActiveSupport is the `MemoryStore` one, so it's important to
configure a proper one for your production environment.

### Logging

You can provide a `:logger` option that will be receive debug informations based on the middleware
operations:

```ruby
client = Faraday.new do |builder|
  builder.use :http_cache, :logger => Rails.logger
  builder.adapter Faraday.default_adapter
end

client.get('http://site/api/users')
# logs "HTTP Cache: [GET users] miss, store"
```

## See it live

You can clone this repository, install it's dependencies with Bundler (run `bundle install`) and
execute the `examples/twitter.rb` file to see a sample of the middleware usage - it's issuing
requests to the Twitter API and caching them, so the rate limit isn't reduced on every request by
the client object. After sleeping for 5 3minutes the cache will expire and the client will hit the
Twitter API again.

## License

Copyright (c) 2012 Plataformatec. See LICENSE file.
