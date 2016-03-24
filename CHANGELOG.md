## Unreleased

* Support only Ruby 2.1+.

## 1.3.1 (2016-08-12)

* Reject invalid `Date` response headers instead of letting the exception bubble.

## 1.3.0 (2016-03-24)

* `no-cache` responses won't be treated as fresh and will always be revalidated.

## 1.2.2 (2015-08-27)

* Update the `CACHE_STATUSES` to properly instrument requests with the `Cache-Control: no-store` header.

## 1.2.1

* Update the `CACHE_STATUSES` to better instrument `invalid` and `uncacheable` responses.

## 1.2.0 (2015-08-14)

* Deprecate the default instrumenter name `process_request.http_cache.faraday`
in favor of `http_cache.faraday`.

## 1.1.1 (2015-06-04)

* Added support for `:instrumenter_name` option.
* 307 responses (`Temporary Redirects`) are now cached.
* Do not crash on non RFC 2616 compliant `Expires` headers.

## 1.1.0 (2015-04-02)

* Instrumentation supported. (by @dasch)
* Illegal headers from `304` responses will be removed before updating the
cached responses. (by @dasch)

## 1.0.1 (2015-01-30)

* Fixed HTTP method matching that failed when using the `Marshal` serializer.
(by @toddmazierski)

## 1.0.0 (2015-01-27)

* Deprecated configuration API removed.
* Better support for the caching mechanisms described in the RFC 7234, including:
  * Reworked the data structures that are stored in the underlying store to
  store responses under the same URL and HTTP method.
  * Cached responses are invalidated after a `PUT`/`POST`/`DELETE` request.
  * Support for the `Vary` header as a second logic to retrieve a stored response.

## 0.4.2 (2014-08-17)

* Header values are explicitly part of the cache key for all requests.

## 0.4.1 (2014-06-26)

* Encoding conversion exceptions will emit a log warning before raising through
the middleware stack. Use `Marshal` instead of `JSON` to serialize such requests.
* Compatible with latest ActiveSupport and Faraday versions.

## 0.4.0 (2014-01-30)
