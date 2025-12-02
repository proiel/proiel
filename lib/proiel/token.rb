#--
# Copyright (c) 2015-2017 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
module PROIEL
  # A token object in a treebank.
  class Token < TreebankObject
    # A class representing a token sentence in the PROIEL treebank.
    extend Memoist

    # @return [Fixnum] ID of the sentence
    attr_reader :id

    # @return [Sentence] parent sentence object
    attr_accessor :sentence

    # @return [nil, Fixnum] ID of head token
    attr_reader :head_id

    # @return [nil, String] token form
    attr_reader :form

    # @return [nil, String] token lemma
    attr_reader :lemma

    # @return [nil, String] token part of speech tag
    attr_reader :part_of_speech

    # @return [nil, String] token part of speech tag
    alias :pos :part_of_speech

    # @return [nil, String] token morphological tag
    attr_reader :morphology

    # @return [nil, String] token relation tag
    attr_reader :relation

    # @return [nil, String] token empty token sort tag
    attr_reader :empty_token_sort

    # @return [nil, String] citation part
    attr_reader :citation_part

    # @return [nil, String] presentation material before form
    attr_reader :presentation_before

    # @return [nil, String] presentation material after form
    attr_reader :presentation_after

    # @return [nil, Fixnum] ID of antecedent token
    attr_reader :antecedent_id

    # @return [nil, String] information status tag
    attr_reader :information_status

    # @return [nil, String] contrast group tag
    attr_reader :contrast_group

    # @return [nil, String] free-form foreign IDs
    attr_reader :foreign_ids

    # @return [Array<Array<String,Fixnum>>] secondary edges as an array of pairs of relation tag and target token ID
    attr_reader :slashes

    # @return [nil, Integer] ID of the sentence that this sentence is aligned to
    attr_reader :alignment_id

    # Creates a new token object.
    def initialize(parent, id, head_id, form, lemma, part_of_speech,
                   morphology, relation, empty_token_sort, citation_part,
                   presentation_before, presentation_after, antecedent_id,
                   information_status, contrast_group, foreign_ids, slashes,
                   alignment_id)
      @sentence = parent

      raise ArgumentError, 'integer expected' unless id.is_a?(Integer)
      @id = id

      raise ArgumentError, 'integer or nil expected' unless head_id.nil? or head_id.is_a?(Integer)
      @head_id = head_id

      raise ArgumentError, 'string or nil expected' unless form.nil? or form.is_a?(String)
      @form = form.freeze

      raise ArgumentError, 'string or nil expected' unless lemma.nil? or lemma.is_a?(String)
      @lemma = lemma.freeze

      raise ArgumentError, 'string or nil expected' unless part_of_speech.nil? or part_of_speech.is_a?(String)
      @part_of_speech = part_of_speech.freeze

      raise ArgumentError, 'string or nil expected' unless morphology.nil? or morphology.is_a?(String)
      @morphology = morphology.freeze

      raise ArgumentError, 'string or nil expected' unless relation.nil? or relation.is_a?(String)
      @relation = relation.freeze

      raise ArgumentError, 'string or nil expected' unless empty_token_sort.nil? or empty_token_sort.is_a?(String)
      @empty_token_sort = empty_token_sort.freeze

      raise ArgumentError, 'string or nil expected' unless citation_part.nil? or citation_part.is_a?(String)
      @citation_part = citation_part.freeze

      raise ArgumentError, 'string or nil expected' unless presentation_before.nil? or presentation_before.is_a?(String)
      @presentation_before = presentation_before.freeze

      raise ArgumentError, 'string or nil expected' unless presentation_after.nil? or presentation_after.is_a?(String)
      @presentation_after = presentation_after.freeze

      raise ArgumentError, 'integer or nil expected' unless antecedent_id.nil? or antecedent_id.is_a?(Integer)
      @antecedent_id = antecedent_id

      raise ArgumentError, 'string or nil expected' unless information_status.nil? or information_status.is_a?(String)
      @information_status = information_status.freeze

      raise ArgumentError, 'string or nil expected' unless contrast_group.nil? or contrast_group.is_a?(String)
      @contrast_group = contrast_group.freeze

      raise ArgumentError, 'string or nil expected' unless foreign_ids.nil? or foreign_ids.is_a?(String)
      @foreign_ids = foreign_ids.freeze

      raise ArgumentError, 'array expected' unless slashes.is_a?(Array)
      @slashes = slashes.map { |s| [s.relation.freeze, s.target_id] }

      raise ArgumentError, 'integer or nil expected' unless alignment_id.nil? or alignment_id.is_a?(Integer)
      @alignment_id = alignment_id
    end

    # @return [Div] parent div object
    def div
      @sentence.div
    end

    # @return [Source] parent source object
    def source
      @sentence.div.source
    end

    # @return [Treebank] parent treebank object
    def treebank
      @sentence.div.source.treebank
    end

    # @return [String] language of the token as an ISO 639-3 language tag
    def language
      source.language
    end

    memoize :language

    # @return [nil, String] a complete citation for the token
    def citation
      if citation_part
        [source.citation_part, citation_part].compact.join(' ')
      else
        nil
      end
    end

    # Returns the printable form of the token with any presentation data.
    #
    # @param custom_token_formatter [Lambda] formatting function for tokens
    # which is passed the token as its sole argument
    #
    # @return [String] the printable form of the token
    def printable_form(custom_token_formatter: nil)
      printable_form =
        if custom_token_formatter
          custom_token_formatter.call(self)
        else
          form
        end

      [presentation_before, printable_form, presentation_after].compact.join
    end

    # @return [Hash<Symbol,String>] token part of speech tag as a hash
    def part_of_speech_hash
      if part_of_speech
        POS_POSITIONAL_TAG_SEQUENCE.zip(part_of_speech.split('')).reject { |_, v| v == '-' }.to_h
      else
        {}
      end
    end

    memoize :part_of_speech_hash

    alias :pos_hash :part_of_speech_hash

    # Returns the part of speech tag if set, but also provides a suitable
    # part of speech tag for empty elements.
    #
    # @return [String] part of speech tag
    def part_of_speech_with_nulls
      part_of_speech || NULL_PARTS_OF_SPEECH[empty_token_sort]
    end

    alias :pos_with_nulls :part_of_speech_with_nulls

    # @return [Hash<Symbol,String>] token morphology tag as a hash
    def morphology_hash
      if morphology
        MORPHOLOGY_POSITIONAL_TAG_SEQUENCE.zip(morphology.split('')).reject { |_, v| v == '-' }.to_h
      else
        {}
      end
    end

    memoize :morphology_hash

    # Checks if the token is the root of its dependency graph.
    #
    # If the token belongs to a sentence that lacks dependency annotation,
    # all tokens are treated as roots. If a sentence has partial or complete
    # dependency annotation there may still be multiple root tokens.
    #
    # @return [true, false]
    def is_root?
      head_id.nil?
    end

    # Finds the head of this token.
    #
    # The head is the parent of the this token in the tree that has tokens as
    # nodes and primary relations as edges.
    #
    # @return [Token] head
    def head
      if is_root?
        nil
      else
        treebank.find_token(head_id)
      end
    end

    memoize :head

    alias :parent :head

    # Finds dependent of this token in the dependency graph.
    #
    # The dependents are the children of the this token in the tree that has
    # tokens as nodes and primary relations as edges.
    #
    # The order of the returned dependents is indeterminate.
    #
    # @return [Array<Token>] dependent
    def dependents
      @sentence.tokens.select { |t| t.head_id == @id }
    end

    memoize :dependents

    alias :children :dependents

    # Finds ancestors of this token in the dependency graph.
    #
    # The ancestors are the ancestors of the this token in the tree that has
    # tokens as nodes and primary relations as edges.
    #
    # The order of the returned ancestors is as follows: The first
    # ancestor is the head of this token, the next ancestor is
    # the head of the previous token, and so on.
    #
    # @return [Array<Token>] ancestors
    def ancestors
      if is_root?
        []
      else
        [head] + head.ancestors
      end
    end

    memoize :ancestors

    # Finds descendents of this token in the dependency graph.
    #
    # The descendents are the ancestors of the this token in the tree that has
    # tokens as nodes and primary relations as edges.
    #
    # The order of the returned descendents is as indeterminate.
    #
    # @return [Array<Token>] descendents
    def descendents
      dependents.map { |dependent| [dependent] + dependent.descendents }.flatten
    end

    memoize :descendents

    alias :descendants :descendents

    # Tests if the token is empty.
    #
    # A token is empty if it does not have a form. If the token is empty,
    # {Token#empty_token_sort} explains its function.
    #
    # @see Token#has_content?
    #
    # @return [true, false]
    def is_empty?
      !empty_token_sort.nil?
    end

    # Tests if the token has content.
    #
    # A token has content if it has a form.
    #
    # @see Token#is_empty?
    #
    # @return [true, false]
    def has_content?
      empty_token_sort.nil?
    end

    # Tests if the token has a citation.
    #
    # A token has a citation if `citation_part` is not `nil`.
    #
    # @return [true, false]
    def has_citation?
      !citation_part.nil?
    end

    # Checks if the token is a PRO token.
    #
    # @return [true, false]
    def pro?
      empty_token_sort == 'P'
    end

    # Finds the common ancestors that this token and another token
    # share in the dependency graph.
    #
    # If `inclusive` is `false`, a common ancestor is defined strictly
    # as a common ancestor of both tokens. If `inclusive` is `true`,
    # one of the tokens can be a common ancestor of the other.
    #
    # Ancestors are returned in the same order as {Token#ancestors}.
    #
    # @example
    #   x.head # => w
    #   w.head # => z
    #   y.head # => z
    #   z.head # => u
    #
    #   x.common_ancestors(y, inclusive: false) # => [z, u]
    #   x.common_ancestors(w, inclusive: false) # => [z, u]
    #   x.common_ancestors(x, inclusive: false) # => [w, z, u]
    #
    #   x.common_ancestors(y, inclusive: true)  # => [z, u]
    #   x.common_ancestors(w, inclusive: true)  # => [w, z, u]
    #   x.common_ancestors(x, inclusive: true)  # => [x, w, z, u]
    #
    # @see Token#first_common_ancestor
    # @see Token#first_common_ancestor_path
    #
    # @return [Array<Token>] common ancestors
    def common_ancestors(other_token, inclusive: false)
      if inclusive
        x, y = [self] + ancestors, [other_token] + other_token.ancestors
      else
        x, y = ancestors, other_token.ancestors
      end

      x & y
    end

    # Finds the first common ancestor that this token and another token
    # share in the dependency graph.
    #
    # If `inclusive` is `false`, a common ancestor is defined strictly
    # as a common ancestor of both tokens. If `inclusive` is `true`,
    # one of the tokens can be a common ancestor of the other.
    #
    # @example
    #   x.head # => w
    #   w.head # => z
    #   y.head # => z
    #   z.head # => u
    #
    #   x.first_common_ancestor(y, inclusive: false) # => z
    #   x.first_common_ancestor(w, inclusive: false) # => z
    #   x.first_common_ancestor(x, inclusive: false) # => w
    #
    #   x.first_common_ancestor(y, inclusive: true)  # => z
    #   x.first_common_ancestor(w, inclusive: true)  # => w
    #   x.first_common_ancestor(x, inclusive: true)  # => x
    #
    # @see Token#common_ancestors
    # @see Token#first_common_ancestor_path
    #
    # @return [nil, Token] first common ancestor
    def first_common_ancestor(other_token, inclusive: false)
      common_ancestors(other_token, inclusive: inclusive).first
    end

    # Returns the aligned token if any.
    #
    # @return [Token, NilClass] aligned token
    def alignment(aligned_source)
      alignment_id ? aligned_source.treebank.find_token(alignment_id) : nil
    end

    # Checks if the token is a conjunction.
    #
    # @return [true, false]
    def conjunction?
      part_of_speech == 'C-' or empty_token_sort == 'C'
    end

    # Computes the depth of the token in the dependency tree.
    #
    # @return [Integer] depth
    def depth
      if is_root?
        0
      else
        head.depth + 1
      end
    end

    # Computes the 1-based index of the token in the sentence.
    #
    # @return [Integer] token number
    def token_number
      sentence.tokens.find_index(self) + 1
    end

    memoize :depth, :token_number

    private

    # FIXME: extract this from the header of the PROIEL XML file instead and
    # subclass PositionalTag
    POS_POSITIONAL_TAG_SEQUENCE = %i(major minor).freeze

    # FIXME: extract this from the header of the PROIEL XML file instead and
    # subclass PositionalTag
    MORPHOLOGY_POSITIONAL_TAG_SEQUENCE = %i(
      person number tense mood voice gender case degree strength inflection
    ).freeze

    NULL_PARTS_OF_SPEECH = {
      'V' => 'V-',
      'C' => 'C-',
      'P' => 'Pp',
    }.freeze
  end
end
