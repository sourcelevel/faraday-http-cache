# Faraday Http Cache

[![Build Status](https://secure.travis-ci.org/plataformatec/faraday-http-cache.png)](https://travis-ci.org/plataformatec/faraday-http-cache)

a [Faraday](https://github.com/lostisland/faraday) middleware that respects HTTP cache,
by checking expiration and validation of the stored responses.

## Installation

Add it to your Gemfile:

```ruby
gem 'faraday-http-cache'
```

## Usage and configuration

You have to use the middleware in the Faraday instance that you want to. You can use the new
shortcut using a symbol or passing the middleware class

```ruby
client = Faraday.new do |builder|
  builder.use :http_cache
  # or
  builder.use Faraday::HttpCache

  builder.adapter Faraday.default_adapter
end
```

The middleware uses the `ActiveSupport::Cache` API to record the responses from the targeted
endpoints, and any extra configuration option will be used to setup the cache store.

```ruby
# Connect the middleware to a Memcache instance.
client = Faraday.new do |builder|
  builder.use :http_cache, :mem_cache_store, 'localhost:11211'
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

MultiJson is used for serialization by default. If you expect to be dealing
with images, you can use [Marshal][marshal] instead.

```ruby
client = Faraday.new do |builder|
  builder.use :http_cache, serializer: Marshal
  builder.adapter Faraday.default_adapter
end
```

### Logging

You can provide a `:logger` option that will be receive debug informations based on the middleware
operations:

```ruby
client = Faraday.new do |builder|
  builder.use :http_cache, logger: Rails.logger
  builder.adapter Faraday.default_adapter
end

client.get('http://site/api/users')
# logs "HTTP Cache: [GET users] miss, store"
```

## See it live

You can clone this repository, install it's dependencies with Bundler (run `bundle install`) and
execute the files under the `examples` directory to see a sample of the middleware usage.

## License

Copyright (c) 2012-2013 Plataformatec. See LICENSE file.

  [marshal]: http://www.ruby-doc.org/core-2.0/Marshal.html
