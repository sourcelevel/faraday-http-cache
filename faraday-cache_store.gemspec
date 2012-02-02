# -*- encoding: utf-8 -*-
require File.expand_path('../lib/faraday/cache_store/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Lucas Mazza"]
  gem.email         = ["contact@plataformatec.com.br"]
  gem.description   = %q{Middleware to handle HTTP caching}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = "http://github.com/plataformatec/faraday-cache_store"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "faraday-cache_store"
  gem.require_paths = ["lib"]
  gem.version       = Faraday::CacheStore::VERSION

  gem.add_dependency 'multi_json'
  gem.add_dependency 'active_support', '~> 3.0'
  gem.add_development_dependency 'faraday', '0.8.0.rc2'
  gem.add_development_dependency 'rspec',   '~> 2.0'
end
