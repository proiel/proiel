#--
# Copyright (c) 2016-2018 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++

# Methods for synthesising and manipulating dictionaries from treebank data.
module PROIEL
  class DictionaryBuilder
    attr_reader :license
    attr_reader :language
    attr_reader :sources
    attr_reader :lemmata

    def initialize
      @language = nil
      @license = nil
      @sources = []
      @lemmata = {}
      @valency = PROIEL::Valency::Lexicon.new
    end

    def add_source!(source)
      raise ArgumentError, 'source expected' unless source.is_a?(PROIEL::Source)
      raise ArgumentError, 'incompatible language' unless @language.nil? or @language == source.language
      raise ArgumentError, 'incompatible license' unless @license.nil? or @license == source.license

      @language ||= source.language
      @license ||= source.license
      @sources << source

      source.tokens.each { |token| index_token!(token) }

      index_homographs!
    end

    CURRENT_SCHEMA_VERSION = '3.0'

    def to_xml(io)
      builder = ::Builder::XmlMarkup.new(target: io, indent: 2)
      builder.instruct! :xml, version: '1.0', encoding: 'UTF-8'
      builder.proiel('export-time': DateTime.now.xmlschema, 'schema-version': CURRENT_SCHEMA_VERSION) do
        builder.dictionary(language: @language) do
          builder.sources do
            @sources.each do |source|
              builder.source(idref: source.id, license: source.license)
            end
          end

          builder.lemmata(n: @lemmata.count) do
            @lemmata.sort_by { |lemma, _| lemma.downcase }.each do |form_and_pos, data|
              form, _ = form_and_pos.split(',')
              lemma_to_xml(builder, form, data)
            end
          end
        end
      end
    end

    def add_external_glosses!(filename, languages = %i(eng))
      raise ArgumentError, 'filename expected' unless filename.is_a?(String)
      raise ArgumentError, 'file not found' unless File.exists?(filename)

      CSV.foreach(filename, headers: true, encoding: 'utf-8', col_sep: "\t", header_converters: :symbol) do |row|
        h = row.to_h
        data = languages.map { |l| [l, h[l]] }.to_h

        lemma = initialize_lemma!(row[:lemma], row[:part_of_speech])
        lemma[:glosses] ||= {}
        lemma[:glosses].merge!(data)
      end
    end

    private

    def initialize_lemma!(lemma, part_of_speech)
      encoded_lemma = [lemma, part_of_speech].join(',')

      @lemmata[encoded_lemma] ||= {}
      @lemmata[encoded_lemma][:lemma] ||= lemma
      @lemmata[encoded_lemma][:part_of_speech] ||= part_of_speech
      @lemmata[encoded_lemma][:homographs] ||= []
      @lemmata[encoded_lemma][:n] ||= 0

      %i(distribution glosses paradigm valency).each do |k|
        @lemmata[encoded_lemma][k] ||= {}
      end

      @lemmata[encoded_lemma]
    end

    def lemma_to_xml(builder, form, data)
      builder.lemma(form: form, "part-of-speech": data[:part_of_speech], n: data[:n]) do
        distribution_to_xml(builder, data)
        glosses_to_xml(builder, data)
        homographs_to_xml(builder, data)
        paradigm_to_xml(builder, data)
        valency_to_xml(builder, data)
      end
    end

    def distribution_to_xml(builder, data)
      unless data[:distribution].empty?
        builder.distribution do
          data[:distribution].sort_by(&:first).each do |source_id, n|
            builder.source(idref: source_id, n: n)
          end
        end
      end
    end

    def glosses_to_xml(builder, data)
      unless data[:glosses].empty?
        builder.glosses do
          data[:glosses].each do |language, value|
            builder.gloss(value, language: language)
          end
        end
      end
    end

    def homographs_to_xml(builder, data)
      if data[:homographs].count > 0
        builder.homographs do
          data[:homographs].each do |homograph|
            lemma, part_of_speech = homograph.split(',')
            builder.homograph lemma: lemma, "part-of-speech": part_of_speech
          end
        end
      end
    end

    def paradigm_to_xml(builder, data)
      unless data[:paradigm].empty?
        builder.paradigm do
          data[:paradigm].sort_by(&:first).each do |morphology, d|
            builder.slot1 morphology: morphology do
              d.sort_by(&:first).each do |form, n|
                builder.slot2 form: form, n: n
              end
            end
          end
        end
      end
    end

    def valency_to_xml(builder, data)
      unless data[:valency].empty?
        builder.valency do
          frames =
            data[:valency].map do |arguments, token_ids|
              { arguments: arguments, tokens: token_ids }
            end

          PROIEL::Valency::Obliqueness.sort_frames(frames).each do |frame|
            builder.frame do
              builder.arguments do
                frame[:arguments].each do |argument|
                  # FIXME: deal with in a better way
                  argument[:"part-of-speech"] = argument[:part_of_speech] if argument[:part_of_speech]
                  argument.delete(:part_of_speech)
                  builder.argument argument
                end
              end

              if frame[:tokens][:a].count > 0
                builder.tokens flags: 'a', n: frame[:tokens][:a].count do
                  frame[:tokens][:a].each do |token_id|
                    builder.token(idref: token_id)
                  end
                end
              end

              if frame[:tokens][:r].count > 0
                builder.tokens flags: 'r', n: frame[:tokens][:r].count do
                  frame[:tokens][:r].each do |token_id|
                    builder.token(idref: token_id)
                  end
                end
              end
            end
          end
        end
      end
    end

    def index_homographs!
      @lemmata.keys.group_by { |l| l.split(',').first }.each do |m, homographs|
        if homographs.count > 1
          homographs.each do |form|
            @lemmata[form][:homographs] = homographs.reject { |homograph| homograph == form }
          end
        end
      end
    end

    def index_token!(token)
      if token.lemma and token.part_of_speech
        lemma = initialize_lemma!(token.lemma, token.part_of_speech)

        lemma[:n] += 1

        lemma[:distribution][token.source.id] ||= 0
        lemma[:distribution][token.source.id] += 1

        lemma[:paradigm][token.morphology] ||= {}
        lemma[:paradigm][token.morphology][token.form] ||= 0
        lemma[:paradigm][token.morphology][token.form] += 1


        # Find verbal nodes
        if token.part_of_speech[/^V/]
          frame = PROIEL::Valency::Arguments.get_argument_frame(token)

          lemma[:valency][frame] ||= { a: [], r: [] }

          entry = lemma[:valency][frame]

          if token.dependents.any? { |d| d.relation == 'aux' and d.part_of_speech == 'Pk' }
            entry[:r] << token.id
          else
            entry[:a] << token.id
          end
        end
      end
    end
  end
end
