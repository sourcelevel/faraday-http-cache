# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.name          = 'faraday-http-cache'
  gem.version       = '0.4.2'
  gem.licenses      = ['Apache 2.0']
  gem.description   = 'Middleware to handle HTTP caching'
  gem.summary       = 'A Faraday middleware that stores and validates cache expiration.'
  gem.authors       = ['Lucas Mazza']
  gem.email         = ['opensource@plataformatec.com.br']
  gem.homepage      = 'https://github.com/plataformatec/faraday-http-cache'

  gem.files         = Dir['LICENSE', 'README.md', 'lib/**/*']
  gem.test_files    = Dir['spec/**/*']
  gem.require_paths = ['lib']
  gem.executables   = []

  gem.add_dependency 'faraday', '>= 0.8'
end
