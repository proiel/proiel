#--
# Copyright (c) 2015-2016 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
module PROIEL
  # A sentence object in a treebank.
  class Sentence < TreebankObject
    extend Memoist

    # @return [Fixnum] ID of the sentence
    attr_reader :id

    # @return [Div] parent div object
    attr_reader :div

    # @return [Symbol] annotation status of sentence
    attr_reader :status

    # @return [nil, String] presentation material before sentence
    attr_reader :presentation_before

    # @return [nil, String] presentation material after sentence
    attr_reader :presentation_after

    # @return [nil, Integer] ID of the sentence that this sentence is aligned to
    attr_reader :alignment_id

    # @return [nil, String] annotator of sentence
    attr_reader :annotated_by

    # @return [nil, String] reviewer of sentence
    attr_reader :reviewed_by

    # @return [nil, DateTime] time of annotation
    attr_reader :annotated_at

    # @return [nil, DateTime] time of reviewed
    attr_reader :reviewed_at

    # Creates a new sentence object.
    def initialize(parent, id, status, presentation_before, presentation_after, alignment_id, annotated_by, reviewed_by, annotated_at, reviewed_at, &block)
      @div = parent

      raise ArgumentError, "integer expected #{id.inspect}" unless id.is_a?(Integer) or id.nil?
      @id = id

      raise ArgumentError, 'string or symbol expected' unless status.is_a?(String) or status.is_a?(Symbol)
      @status = status.to_sym

      raise ArgumentError, 'string or nil expected' unless presentation_before.nil? or presentation_before.is_a?(String)
      @presentation_before = presentation_before.freeze

      raise ArgumentError, 'string or nil expected' unless presentation_after.nil? or presentation_after.is_a?(String)
      @presentation_after = presentation_after.freeze

      raise ArgumentError, 'integer or nil expected' unless alignment_id.nil? or alignment_id.is_a?(Integer)
      @alignment_id = alignment_id

      raise ArgumentError, 'XML schema date time or nil expected' unless annotated_at.nil? or PROIEL::Utilities.xmlschema_datetime?(annotated_at)
      @annotated_at = annotated_at ? DateTime.xmlschema(annotated_at).freeze : nil

      raise ArgumentError, 'XML schema date time or nil expected' unless reviewed_at.nil? or PROIEL::Utilities.xmlschema_datetime?(reviewed_at)
      @reviewed_at = reviewed_at ? DateTime.xmlschema(reviewed_at).freeze : nil

      raise ArgumentError, 'string or nil expected' unless annotated_by.nil? or annotated_by.is_a?(String)
      @annotated_by = annotated_by.freeze

      raise ArgumentError, 'string or nil expected' unless reviewed_by.nil? or reviewed_by.is_a?(String)
      @reviewed_by = reviewed_by.freeze

      @children = block.call(self) if block_given?
    end

    # @return [Source] parent source object
    def source
      @div.source
    end

    # @return [Treebank] parent treebank object
    def treebank
      @div.source.treebank
    end

    # @return [String] language of the sentence as an ISO 639-3 language tag
    def language
      source.language
    end

    memoize :language

    # @return [String] the complete citation for the sentence
    def citation
      [source.citation_part, citation_part].join(' ')
    end

    # Computes an appropriate citation component for the sentence.
    #
    # The computed citation component must be concatenated with the citation
    # component provided by the source to produce a complete citation.
    #
    # @see citation
    #
    # @return [String] the citation component
    def citation_part
      tc = @children.select(&:has_citation?)
      x = tc.first ? tc.first.citation_part : nil
      y = tc.last ? tc.last.citation_part : nil

      Citations.citation_make_range(x, y)
    end

    # Returns the printable form of the sentence with all token forms and any
    # presentation data.
    #
    # @return [String] the printable form of the sentence
    def printable_form(options = {})
      [presentation_before,
       @children.map { |t| t.printable_form(options) },
       presentation_after].compact.join
    end

    # Checks if the sentence is reviewed.
    #
    # A sentence has been reviewed if its `status` is `:reviewed`.
    #
    # @return [true,false]
    def reviewed?
      @status == :reviewed
    end

    # Checks if the sentence is annotated.
    #
    # Since only annotated sentences can be reviewed, a sentence is annotated
    # if its `status` is either `:reviewed` or `:annotated`.
    #
    # @return [true,false]
    def annotated?
      @status == :reviewed or @status == :annotated
    end

    # Checks if the sentence is unannotated.
    #
    # A sentence is unannotated if its `status` is `:unannotated`.
    #
    # @return [true,false]
    def unannotated?
      @status == :unannotated
    end

    # Builds a syntax graph for the dependency annotation of the sentence and
    # inserts a dummy root node. The graph is represented as a hash of
    # hashes.  Each hash contains the ID of the token, its relation (to its
    # syntatically dominating token) and a list of secondary edges.
    #
    # @return [Hash] a single graph with a dummy root node represented as a hash
    #
    # @example
    #
    #   sentence.syntax_graph # => [id: nil, relation: nil, children: [{ id: 1000, relation: "pred", children: [ { id: 1001, relation: "xcomp", children: [], slashes: [["xsub", 1000]]}]}], slashes: []]
    #
    def syntax_graph
      { id: nil, relation: nil, children: syntax_graphs, slashes: [] }
    end

    # Builds syntax graphs for the dependency annotation of the sentence.
    # Multiple graphs may be returned as the function does not insert an
    # empty dummy root node. Each graph is represented as a hash of hashes.
    # Each hash contains the ID of the token, its relation (to its
    # syntatically dominating token) and a list of secondary edges.
    #
    # @return [Array] zero or more syntax graphs represented as hashes
    #
    # @example Get a single syntax graph with a dummy root node
    #
    #  sentence.syntax_graphs # => [{ id: 1000, relation: "pred", children: [ { id: 1001, relation: "xcomp", children: [], slashes: [["xsub", 1000]]}]}]
    #
    def syntax_graphs
      Array.new.tap do |graphs|
        token_map = {}

        # Pass 1: create new attribute hashes for each token and index each hash by token ID
        @children.each do |token|
          token_map[token.id] =
            {
              id: token.id,
              relation: token.relation,
              children: [],
              slashes: token.slashes,
            }
        end

        # Pass 2: append attribute hashes for tokens with a head ID to the head's children list; append attribute hashes for tokens without a head ID to the list of graphs to return
        @children.each do |token|
          if token.head_id
            token_map[token.head_id][:children] << token_map[token.id]
          else
            graphs << token_map[token.id]
          end
        end
      end
    end

    # Finds all tokens in the sentence.
    #
    # @return [Enumerator] tokens in the sentence
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
      @children.to_enum
    end
  end
end
