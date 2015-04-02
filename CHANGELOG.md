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
