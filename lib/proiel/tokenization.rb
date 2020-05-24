#--
# Copyright (c) 2015 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
module PROIEL
  module Tokenization
    # Loads tokenization patterns from a configuration file.
    #
    # The configuration file should be a JSON file. The keys should
    # be language tags and the values tokenization patterns.
    #
    # The method can be called multiple times. On the first invocation
    # patterns will be loaded, on subsequent invocations patterns will
    # be updated. Only patterns for languages that are defined in the
    # configuration file will be updated, other patterns will remain unchanged.
    #
    # @param filename [String] name of tokenization pattern file
    #
    # @return [Hash] loaded patterns
    #
    def self.load_patterns(filename)
      raise ArgumentError, 'invalid filename' unless filename.is_a?(String)

      patterns = JSON.parse(File.read(filename))

      regexes = patterns.map { |l, p| [l, make_regex(p)] }.to_h

      @@regexes ||= {}
      @@regexes.merge!(regexes)
    end

    # Makes a regular expression from a pattern given in the configuration file.
    #
    # The regular expression is to avoid partial matches. Multi-line matches
    # are allowed in case characters that are interpreted as line separators
    # occur in the data.
    #
    # @param pattern [String] tokenization pattern
    #
    # @return [Regexp]
    #
    def self.make_regex(pattern)
      raise ArgumentError, 'invalid pattern' unless pattern.is_a?(String)

      Regexp.new("^#{pattern}$", Regexp::MULTILINE)
    end

    # Tests if a token form is splitable. Any form with more than one character
    # is splitable.
    #
    # @param form [String, nil] token form to Tests
    #
    # @return [true, false]
    #
    def self.is_splitable?(form)
      raise ArgumentError, 'invalid form' unless form.is_a?(String) or form.nil?

      form and form.length > 1
    end

    WORD_PATTERN = /([^[\u{E000}-\u{F8FF}][[:word:]]]+)/

    # Splits a token form using the tokenization patterns that apply for a
    # the specified language. Tokenization patterns must already have been
    # loaded.
    #
    # @param language_tag [String] ISO 639-3 tag for the language whose patterns
    #   should be used to split the token form
    # @param form [String] token form to split
    #
    # @return [Array<String>]
    #
    def self.split_form(language_tag, form)
      raise ArgumentError, 'invalid language tag' unless language_tag.is_a?(String)
      raise ArgumentError, 'invalid form' unless form.is_a?(String)

      if form[WORD_PATTERN]
        # Split on any non-word character like a space or punctuation
        form.split(WORD_PATTERN)
      elsif @@regexes.key?(language_tag) and form[@@regexes[language_tag]]
        # Apply language-specific pattern
        form.match(@@regexes[language_tag]).captures
      elsif form == ''
        ['']
      else
        # Give up and split by character
        form.split(/()/)
      end
    end
  end
end
