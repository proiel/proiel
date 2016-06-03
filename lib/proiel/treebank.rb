#--
# Copyright (c) 2015-2016 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
module PROIEL
  # Schema mismatch error.
  #
  # This represents an error that occurs when a treebank source is loaded
  # into a {Treebank} object that already contains sources defined with an
  # incompatible schema.
  class SchemaMismatch < RuntimeError; end

  # A class representing a PROIEL treebank containing any number of sources.
  # The sources must use the same annotation scheme.
  class Treebank
    # @return [AnnotationSchema] annotation schema for the treebank
    attr_reader :annotation_schema

    # @return [String] PROIEL XML schema version for the treebank
    attr_reader :schema_version

    # @return [Array<Source>] sources in the treebank
    attr_reader :sources

    # Available metadata elements for sources.
    METADATA_ELEMENTS = %i(
      title
      author
      citation_part
      principal
      funder
      distributor
      distributor_address
      date
      license
      license_url
      reference_system
      editor
      editorial_note
      annotator
      reviewer
      electronic_text_editor
      electronic_text_title
      electronic_text_version
      electronic_text_publisher
      electronic_text_place
      electronic_text_date
      electronic_text_original_url
      electronic_text_license
      electronic_text_license_url
      printed_text_editor
      printed_text_title
      printed_text_edition
      printed_text_publisher
      printed_text_place
      printed_text_date
    )

    # Creates a new treebank object.
    def initialize
      @annotation_schema = nil
      @schema_version = nil
      @sources = []

      @source_index = {}
      @div_index = {}
      @sentence_index = {}
      @token_index = {}

      @generated_ids = { div: 0, sentence: 0, token: 0 }
    end

    # Loads one or more PROIEL XML files.
    #
    # @param f [String, IO, Array] PROIEL XML files to load
    #
    # @return [Treebank] treebank object
    #
    def load_from_xml(f)
      case f
      when Array
        f.each { |filename| load_from_xml(filename) }
      when String
        load_from_xml(File.open(f))
      when IO
        tf = PROIELXML::Reader.parse_io(f)

        tf.proiel.sources.each do |s|
          @sources << Source.new(self, s.id, tf.proiel.export_time, s.language,
                                 bundle_metadata(s), s.alignment_id) do |source|
            build_divs(s, source)
          end

          index_objects!(@sources.last)
        end

        annotation_schema = AnnotationSchema.new(tf.proiel.annotation)
        schema_version = tf.proiel.schema_version

        @annotation_schema ||= annotation_schema
        @schema_version ||= schema_version

        if @annotation_schema == annotation_schema and @schema_version == schema_version
          # FIXME: consolidate export times? This is a design flaw in PROIEL XML
          # 2.0: export time ought to be per source not per PROIEL XML file, so
          # not clear what to do here. Pass it down to the source object?
          #@export_time = tf.proiel.export_time
        else
          raise SchemaMismatch
        end
      else
        raise ArgumentError, 'expected filename, IO or array of these'
      end

      self
    end

    # Finds the {Source} object corresponding to a source ID.
    #
    # @param id [String]
    #
    # @return [nil, Source]
    def find_source(id)
      raise ArgumentError, 'string expected' unless id.is_a?(String)

      @source_index[id]
    end

    # Finds the {Div} object corresponding to a div ID.
    #
    # @param id [Integer]
    #
    # @return [nil, Div]
    def find_div(id)
      raise ArgumentError, 'integer expected' unless id.is_a?(Integer)

      @div_index[id]
    end

    # Finds the {Sentence} object corresponding to a sentence ID.
    #
    # @param id [Integer]
    #
    # @return [nil, Sentence]
    def find_sentence(id)
      raise ArgumentError, 'integer expected' unless id.is_a?(Integer)

      @sentence_index[id]
    end

    # Finds the {Token} object corresponding to a token ID.
    #
    # @param id [Integer]
    #
    # @return [nil, Token]
    def find_token(id)
      raise ArgumentError, 'integer expected' unless id.is_a?(Integer)

      @token_index[id]
    end

    private

    def make_id(actual_id, level)
      @generated_ids[level] += 1
      actual_id || @generated_ids[level]
    end

    def bundle_metadata(s)
      METADATA_ELEMENTS.map { |f| [f, s.send(f)] }.to_h
    end

    def build_divs(s, source)
      # For PROIEL XML 2.0 we generate an ID, for PROIEL XML >= 2.1 we respect the ID
      # from the XML file.
      s.divs.each_with_index.map do |d|
        Div.new(source,
                make_id(d.id, :div),
                d.title, d.presentation_before,
                d.presentation_after, d.alignment_id) do |div|
          build_sentences(d, div)
        end
      end
    end

    def build_sentences(d, div)
      d.sentences.map do |e|
        Sentence.new(div,
                     make_id(e.id, :sentence), e.status, e.presentation_before,
                     e.presentation_after, e.alignment_id,
                     e.annotated_by, e.reviewed_by, e.annotated_at,
                     e.reviewed_at) do |sentence|
          build_tokens(e, sentence)
        end
      end
    end

    def build_tokens(e, sentence)
      e.tokens.map do |t|
        Token.new(sentence,
                  make_id(t.id, :token),
                  t.head_id, t.form, t.lemma,
                  t.part_of_speech, t.morphology, t.relation,
                  t.empty_token_sort, t.citation_part,
                  t.presentation_before, t.presentation_after,
                  t.antecedent_id, t.information_status,
                  t.contrast_group, t.foreign_ids,
                  t.slashes, t.alignment_id)
      end
    end

    def index_objects!(source)
      @source_index[source.id] = source

      source.divs.each do |div|
        @div_index[div.id] = div

        div.sentences.each do |sentence|
          @sentence_index[sentence.id] = sentence

          sentence.tokens.each do |token|
            @token_index[token.id] = token
          end
        end
      end
    end
  end
end
