lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'proiel/version'

Gem::Specification.new do |spec|
  spec.name          = 'proiel'
  spec.version       = PROIEL::VERSION
  spec.authors       = ["Marius L. Jøhndal"]
  spec.email         = ["mariuslj@ifi.uio.no"]
  spec.summary       = 'A library for working with treebanks using the PROIEL dependency format'
  spec.description   = 'This provides a library of functions for reading and manipulating treebanks using the PROIEL dependency format.'
  spec.homepage      = 'http://proiel.github.com'
  spec.license       = 'MIT'

  spec.files         = Dir["{bin,examples,contrib,lib}/**/*"] + %w(README.md LICENSE)
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7'

  spec.add_dependency 'builder', '~> 3.2.4'
  spec.add_dependency 'json', '~> 2.3.0'
  spec.add_dependency 'memoist', '~> 0.16.2'
  spec.add_dependency 'nokogiri', '>= 1.14'
  spec.add_dependency 'sax-machine', '~> 1.3.2'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 13.0.1'
  spec.add_development_dependency 'rspec', '~> 3.9.0'
  spec.add_development_dependency 'yard', '~> 0.9.25'
end
