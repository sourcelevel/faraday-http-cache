# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.name          = "faraday-http-cache"
  gem.version       = "0.1.1"
  gem.description   = %q{Middleware to handle HTTP caching}
  gem.summary       = %q{A Faraday middleware that stores and validates cache expiration.}
  gem.authors       = ["Lucas Mazza"]
  gem.email         = ["contact@plataformatec.com.br"]
  gem.homepage      = "https://github.com/plataformatec/faraday-http-cache"

  gem.files         = Dir["LICENSE", "README.md", "lib/**/*"]
  gem.test_files    = Dir["spec/**/*"]
  gem.require_paths = ["lib"]

  gem.add_dependency 'activesupport', '>= 3.0'
  gem.add_dependency 'faraday', '~> 0.8'
  gem.add_dependency 'multi_json', '~> 1.3'
end
