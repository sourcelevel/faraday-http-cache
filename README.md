# Faraday Http Cache

[![Build Status](https://secure.travis-ci.org/plataformatec/faraday-http-cache.png?branch=master)](https://travis-ci.org/plataformatec/faraday-http-cache)

a [Faraday](https://github.com/lostisland/faraday) middleware that respects HTTP cache,
by checking expiration and validation of the stored responses.

## Installation

Add it to your Gemfile:

```ruby
gem 'faraday-http-cache'
```

## Usage and configuration

You have to use the middleware in the Faraday instance that you want to,
along with a suitable `store` to cache the responses. You can use the new
shortcut using a symbol or passing the middleware class

```ruby
client = Faraday.new do |builder|
  builder.use :http_cache, store: :memory_store
  # or
  builder.use Faraday::HttpCache, store: :memory_store

  builder.adapter Faraday.default_adapter
end
```

The middleware uses the `ActiveSupport::Cache` API to record the responses from the targeted
endpoints, and any extra configuration option will be used to setup the cache store.

```ruby
# Connect the middleware to a Memcache instance.
client = Faraday.new do |builder|
  builder.use :http_cache, store: :mem_cache_store, store_options: ['localhost:11211']
  builder.adapter Faraday.default_adapter
end

# Or use the Rails.cache instance inside your Rails app.
client = Faraday.new do |builder|
  builder.use :http_cache, store: Rails.cache
  builder.adapter Faraday.default_adapter
end
```

The default store provided by ActiveSupport is the `MemoryStore` one, so it's important to
configure a proper one for your production environment.

the stdlib `JSON` module is used for serialization by default.
If you expect to be dealing with images, you can use [Marshal][marshal] instead, or
if you want to use another json library like `oj` or `yajl-ruby`.

```ruby
client = Faraday.new do |builder|
  builder.use :http_cache, store: Rails.cache, serializer: Marshal
  builder.adapter Faraday.default_adapter
end
```

### Logging

You can provide a `:logger` option that will be receive debug informations based on the middleware
operations:

```ruby
client = Faraday.new do |builder|
  builder.use :http_cache, store: Rails.cache, logger: Rails.logger
  builder.adapter Faraday.default_adapter
end

client.get('http://site/api/users')
# logs "HTTP Cache: [GET users] miss, store"
```

## See it live

You can clone this repository, install it's dependencies with Bundler (run `bundle install`) and
execute the files under the `examples` directory to see a sample of the middleware usage.

## What get's cached?

The middleware will use the following headers to make caching decisions:
- Cache-Control
- Age
- Last-Modified
- ETag
- Expires

### Cache-Control

The `max-age`, `must-revalidate`, `proxy-revalidate` and `s-maxage` directives are checked.

Note: private caches are ignored.

## License

Copyright (c) 2012-2014 Plataformatec. See LICENSE file.

  [marshal]: http://www.ruby-doc.org/core-2.0/Marshal.html
