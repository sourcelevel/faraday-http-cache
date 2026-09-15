## [3.0.0](https://github.com/sourcelevel/faraday-http-cache/compare/v2.8.0...v3.0.0) (2026-09-15)


### ⚠ BREAKING CHANGES

* Test on Ruby 3.3 to 4.0 and require Ruby 3.3 ([#151](https://github.com/sourcelevel/faraday-http-cache/issues/151))

### Bug Fixes

* Ignore max-age and s-maxage directives without a value ([#152](https://github.com/sourcelevel/faraday-http-cache/issues/152)) ([d7e3e91](https://github.com/sourcelevel/faraday-http-cache/commit/d7e3e915d68d91302f9136faed8ed927b97c87e4))
* Invalidate the request URL even when the response has no headers ([#153](https://github.com/sourcelevel/faraday-http-cache/issues/153)) ([e7aa611](https://github.com/sourcelevel/faraday-http-cache/commit/e7aa6116e63ba5431088b10e354625e2b8c820f9)), closes [#142](https://github.com/sourcelevel/faraday-http-cache/issues/142)


### Miscellaneous

* Test on Ruby 3.3 to 4.0 and require Ruby 3.3 ([#151](https://github.com/sourcelevel/faraday-http-cache/issues/151)) ([221ccec](https://github.com/sourcelevel/faraday-http-cache/commit/221ccec272d258571b18e45eac5f04bbae26eadd))


### Continuous Integration

* Install the bundle before publishing to RubyGems ([#148](https://github.com/sourcelevel/faraday-http-cache/issues/148)) ([6b67002](https://github.com/sourcelevel/faraday-http-cache/commit/6b67002af3d1991e09eb5f9626198e7eedc9f65c))
* Publish to RubyGems with trusted publishing ([#150](https://github.com/sourcelevel/faraday-http-cache/issues/150)) ([5090892](https://github.com/sourcelevel/faraday-http-cache/commit/5090892ee1ad39eb627428184fcb3be9e6049827))

## [2.8.0](https://github.com/sourcelevel/faraday-http-cache/compare/v2.7.0...v2.8.0) (2026-09-15)


### Bug Fixes

* Parse JSON cache entries safely and stop sharing authenticated responses ([#147](https://github.com/sourcelevel/faraday-http-cache/issues/147)) ([64754d5](https://github.com/sourcelevel/faraday-http-cache/commit/64754d5859f806c7f480a29f00f24a75a1bdac88))
* release-please version-file config and workflow API key auth ([4fd5dd3](https://github.com/sourcelevel/faraday-http-cache/commit/4fd5dd3400740b8ca8bfbf040cd570171b18bc8b))
* use API key for RubyGems publish instead of OIDC trusted publishing ([dd859d2](https://github.com/sourcelevel/faraday-http-cache/commit/dd859d24a11a0f873a88cf496ad5f2f41153c9d7))


### Miscellaneous

* Release 2.8.0 ([56c567b](https://github.com/sourcelevel/faraday-http-cache/commit/56c567b9f43546ed7179b3f80efdace800d7dbb8))


### Documentation

* Add a security policy ([#145](https://github.com/sourcelevel/faraday-http-cache/issues/145)) ([9414b3b](https://github.com/sourcelevel/faraday-http-cache/commit/9414b3b7d1fdd3ad3eacdfc7a12062e2062a0c6a))


### Continuous Integration

* Pin json below 3 when testing against Faraday 1 ([#146](https://github.com/sourcelevel/faraday-http-cache/issues/146)) ([59d4263](https://github.com/sourcelevel/faraday-http-cache/commit/59d42635bc5a8014f0fadd8436a231cda5792d2a))

## [2.7.0](https://github.com/sourcelevel/faraday-http-cache/compare/v2.6.1...v2.7.0) (2026-04-14)


### Features

* Added support for `Cache-Control: stale-while-revalidate` ([#139](https://github.com/sourcelevel/faraday-http-cache/pull/139))
* Added `:on_stale` middleware callback hook to trigger custom background refresh logic when stale cached responses are served ([#139](https://github.com/sourcelevel/faraday-http-cache/pull/139))


### Miscellaneous

* add release-please for automated releases to RubyGems ([3e0f9ff](https://github.com/sourcelevel/faraday-http-cache/commit/3e0f9ff2a132438dda0c4980133a8cddf15a448d))
* release 2.7.0 ([a79c386](https://github.com/sourcelevel/faraday-http-cache/commit/a79c386a882b6a4a4ca0f3903794cc5619d7a705))

## 2.5.1 (2024-01-16)

* Support headers passed in using string keys when Vary header is in a different case via #137 (thanks @evman182)

## 2.5.0 (2023-04-27)

* Add `reason_phrase` from the HTTP response to the data stored in the cache according to [RFC7230](https://www.rfc-editor.org/rfc/rfc7230#section-3.1.2) via [#134](https://github.com/sourcelevel/faraday-http-cache/pull/134)

## 2.4.1 (2022-08-08)

* Require `Logger` in `BaseStrategy` via [#131](https://github.com/sourcelevel/faraday-http-cache/pull/131)
* Use unique and sorted headers from the Vary header in `ByVary` strategy via [#132](https://github.com/sourcelevel/faraday-http-cache/pull/132)

## 2.4.0 (2022-06-07)

* Introduced a new `strategy` option to support different cache storage strategies.
* The original strategy moved from `Faraday::HttpCache::Storage` to `Faraday::HttpCache::Strategies::ByUrl`.
* The new `Faraday::HttpCache::Strategies::ByVary` strategy uses headers from `Vary` header to generate cache keys. It also uses the index with `Vary` headers mapped to the request URL.
* `Faraday::HttpCache::Storage` class deprecated.

## 2.3.0 (2022-05-25)

* Added support for Ruby 3.0, 3.1.
* Ruby version constraint changed to 2.4.0.

## 2.2.0 (2019-04-13)

* Support for faraday 1.x

## 2.0.0 (2016-11-16)

* Ruby version constraint changed to 2.1.0.
* Changed `Faraday::HttpCache#initialize` to use keyword arguments instead of
a `Hash`.

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
