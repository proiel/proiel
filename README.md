# PROIEL treebank utility library

## Status

[![Gem Version](https://badge.fury.io/rb/proiel.svg)](http://badge.fury.io/rb/proiel)

## Description

This is a utility library for reading and manipulating treebanks that use the
PROIEL annotation scheme and the PROIEL XML-based interchange format.

## Installation

This library requires Ruby >= 2.7 (as this is what Nokogiri 1.14.x requires).

Install as

```shell
gem install proiel
```

## Getting started

The recommended way to use this library in your application is with `bundler`.
Create a `Gemfile` with the following content:

```ruby
source 'https://rubygems.org'
gem 'proiel', '~> 1.0'
```

and then execute

```shell
bundle
```

To download a sample treebank, initialize a new git repository and add the
[PROIEL treebank](https://proiel.github.io) as a submodule:

```shell
git init
mkdir vendor
git submodule add --depth 1 https://github.com/proiel/proiel-treebank.git vendor/proiel-treebank
```

Here is a skeleton programme to get you started. Save this as `myproject.rb`:

```ruby
#!/usr/bin/env ruby
require 'proiel'

tb = PROIEL::Treebank.new
Dir[File.join('vendor', 'proiel-treebank', '*.xml')].each do |filename|
  puts "Reading #{filename}..."
  tb.load_from_xml(filename)
end

tb.sources.each do |source|
  source.divs.each do |div|
    div.sentences.each do |sentence|
      sentence.tokens.each do |token|
        # Do something
      end
    end
  end
end
```

You can now run this as:

```shell
bundle exec ruby myproject.rb
```

## Versioning

`proiel` aims to adhere to [Semantic Versioning 2.0.0](http://semver.org/spec/v2.0.0.html). This means that a patch version or minor version should not break backward compatibility of a public API, and that breaking changes should only be introduced with new major versions. When specifying a dependency on this gem it is best practice to use a pessimistic version constraint with two digits of precision:

```ruby
spec.add_dependency 'proiel', '~> 1.0'
```

## Development

Check out the git repository from GitHub and run `bundle install` to install
all development dependencies. Then run `bundle exec rake` to run the tests.

To install a development version of this gem, run `bundle exec rake install`.

### Releasing a new version

To release a new version:

1.  Update the version number in `lib/proiel/version.rb`.
2.  Run `bundle exec rake release`. This will:
    *   Create a git tag for the version.
    *   Push git commits and tags to the remote repository.
    *   Push the `.gem` file to [rubygems.org](https://rubygems.org).

## Documentation

Documentation can be generated using YARD:

```sh
yard
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/syntacticus/proiel.
