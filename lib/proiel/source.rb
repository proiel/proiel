#--
# Copyright (c) 2015 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
module PROIEL
  # A source object in a treebank.
  class Source < TreebankObject
    # @return [String] ID of the source
    attr_reader :id

    # @return [Treebank] treebank that the div belongs to
    attr_reader :treebank

    # @return [String] language of the source as an ISO 639-3 language tag
    attr_reader :language

    # @return [DateTime] export time for the source
    attr_reader :export_time

    # @return [Hash{Symbol, String}] metadata fields for the source
    # @see PROIEL::Treebank::METADATA_ELEMENTS
    attr_reader :metadata

    # Creates a new source object.
    def initialize(parent, id, export_time, language, metadata, &block)
      @treebank = parent
      @id = id.freeze
      @export_time = DateTime.parse(export_time).freeze
      @language = language.freeze
      @metadata = metadata.freeze
      @children = block.call(self) if block_given?
    end

    # @return [String] a complete citation for the source
    def citation
      citation_part
    end

    # Returns the printable form of the source with all token forms and any
    # presentation data.
    #
    # @return [String] the printable form of the source
    def printable_form(options = {})
      @children.map { |d| d.printable_form(options) }.compact.join
    end

    # Accesses metadata fields.
    #
    # @see PROIEL::Treebank::METADATA_ELEMENTS
    def method_missing(method_name, *args, &block)
      if @metadata.key?(method_name) and args.empty?
        @metadata[method_name]
      else
        super
      end
    end

    # Finds all divs in the source.
    #
    # @return [Enumerator] divs in the source
    def divs
      @children.to_enum
    end

    # Finds all sentences in the source.
    #
    # @return [Enumerator] sentences in the source
    #
    # @example Iterating sentences
    #   sentences.each { |s| puts s.id }
    #
    # @example Create an array with only reviewed sentences
    #   sentences.select(&:reviewed?)
    #
    # @example Counting sentences
    #   sentences.count #=> 200
    #
    def sentences
      Enumerator.new do |y|
        @children.each do |div|
          div.sentences.each do |sentence|
            y << sentence
          end
        end
      end
    end

    # Finds all tokens in the source.
    #
    # @return [Enumerator] tokens in the source
    #
    # @example Iterating tokens
    #   tokens.each { |t| puts t.id }
    #
    # @example Create an array with only empty tokens
    #   tokens.select(&:is_empty?)
    #
    # @example Counting tokens
    #   puts tokens.count #=> 200
    #
    def tokens
      Enumerator.new do |y|
        @children.each do |div|
          div.sentences.each do |sentence|
            sentence.tokens.each do |token|
              y << token
            end
          end
        end
      end
    end
  end
end
