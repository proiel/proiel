#--
# Copyright (c) 2015-2016 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
module PROIEL
  # A source object in a treebank.
  class Source < TreebankObject
    # @return [String] ID of the source
    attr_reader :id

    # @return [Treebank] treebank that this source belongs to
    attr_reader :treebank

    # @return [String] language of the source as an ISO 639-3 language tag
    attr_reader :language

    # @return [String] dialect of the source
    attr_reader :dialect

    # @return [DateTime] export time for the source
    attr_reader :export_time

    # @return [Hash{Symbol, String}] metadata fields for the source
    # @see PROIEL::Treebank::METADATA_ELEMENTS
    attr_reader :metadata

    # @return [nil, String] ID of the source that this source is aligned to
    attr_reader :alignment_id

    # Creates a new source object.
    def initialize(parent, id, export_time, language, dialect, metadata, alignment_id, &block)
      @treebank = parent
      @id = id.freeze

      raise ArgumentError, 'string or nil expected' unless export_time.nil? or export_time.is_a?(String)
      @export_time = export_time.nil? ? nil : DateTime.parse(export_time).freeze

      @language = language.freeze
      @dialect = dialect ? dialect.freeze : nil
      @metadata = metadata.freeze

      raise ArgumentError, 'string or nil expected' unless alignment_id.nil? or alignment_id.is_a?(String)
      @alignment_id = alignment_id.freeze

      @children = block.call(self) if block_given?
    end

    # @return [String] a complete citation for the source
    def citation
      citation_part
    end

    # Returns the printable form of the source with all token forms and any
    # presentation data.
    #
    # @param custom_token_formatter [Lambda] formatting function for tokens
    # which is passed the token as its sole argument
    #
    # @return [String] the printable form of the source
    def printable_form(custom_token_formatter: nil)
      @children.map { |d| d.printable_form(custom_token_formatter: custom_token_formatter) }.compact.join
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
