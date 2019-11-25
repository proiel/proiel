# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'proiel/version'

Gem::Specification.new do |spec|
  spec.name          = "proiel"
  spec.version       = PROIEL::VERSION
  spec.authors       = ["Marius L. Jøhndal"]
  spec.email         = ["mariuslj@ifi.uio.no"]
  spec.summary       = %q{A library for working with treebanks using the PROIEL dependency format}
  spec.description   = %q{This provides a library of functions for reading and manipulating treebanks using the PROIEL dependency format.}
  spec.homepage      = "http://proiel.github.com"
  spec.license       = "MIT"

  spec.files         = Dir["{bin,examples,contrib,lib}/**/*"] + %w(README.md LICENSE)
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.2'

  spec.add_dependency 'json'
  spec.add_dependency 'nokogiri', '~> 1.8'
  spec.add_dependency 'sax-machine', '~> 1.3'
  spec.add_dependency 'memoist', '~> 0.12'
  spec.add_dependency 'builder', '~> 3.2'

  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'simplecov', '~> 0.14'
  spec.add_development_dependency 'yard', '~> 0.9'
end
