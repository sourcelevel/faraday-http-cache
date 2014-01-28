# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.name          = 'foundry-http-cache'
  gem.version       = '0.4.0.dev'
  gem.licenses      = ['Apache 2.0']
  gem.description   = 'Fork of faraday-http-cache Middleware to handle HTTP caching'
  gem.summary       = 'A Faraday middleware that stores and validates cache expiration.'
  gem.authors       = ['Lucas Mazza']
  gem.email         = ['opensource@plataformatec.com.br']
  gem.homepage      = 'https://github.com/plataformatec/foundry-http-cache'

  gem.files         = Dir['LICENSE', 'README.md', 'lib/**/*']
  gem.test_files    = Dir['spec/**/*']
  gem.require_paths = ['lib']

  gem.add_dependency 'activesupport', '>= 3.0'
  gem.add_dependency 'faraday', '~> 0.8'
end
