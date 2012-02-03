# Faraday Cache Store
A `Faraday` middleware to handle HTTP caching on your client application, validating expiration headers from previous responses.

## Installation

Add it to your Gemfile:

```ruby
gem 'faraday-cache_store'
```

## Usage and configuration

Just add the `cache_store` middleware to your Faraday stack, as in:

```rails
client = Faraday.new do |builder|
  builder.middleware :cache_store
end
```

The middleware uses the `ActiveSupport::Cache` API to record the responses from the targeted endpoints, and any extra configuration option will be used to setup the cache store.

```ruby
# Connect the middleware to a Memcache instance.
client = Faraday.new do |builder|
  builder.middleware :cache_store, :mem_cache_store, "localhost:11211"
end
```

The default store provided by ActiveSupport is the `MemoryStore` one, so it's important to configure a proper one for your production environment.

## Dependencies

`faraday-cache_store` is built on top of `faraday` 0.8.x and `active_support` 3.x.