module PROIEL
  module Valency
    class Lexicon
      attr_reader :frames

      def initialize
        @source_ids = Set.new
        @source_languages = Set.new
        @frames = {}
      end

      # Generates a valency lexicon from the provided sources. In practice the
      # sources should be in the same language but this is not enforced. This
      # makes it possible to generate a lexicon from sources in closely related
      # languages or dialects.
      def add_source!(source)
        @source_ids << source.id
        @source_languages << source.language

        source.sentences.each do |sentence|
          tokens = find_verbal_nodes(sentence)
          tokens.each do |token|
            frame = PROIEL::Valency::Arguments.get_argument_frame(token)

            partition =
              if token.dependents.any? { |d| d.relation == 'aux' and d.part_of_speech == 'Pk' }
                :r
              else
                :a
              end

            @frames[token.lemma] ||= {}
            @frames[token.lemma][token.part_of_speech] ||= {}
            @frames[token.lemma][token.part_of_speech][frame] ||= { a: [], r: [] }
            @frames[token.lemma][token.part_of_speech][frame][partition] << token.id
          end
        end
      end

      def lookup(lemma, part_of_speech)
        frames =
          @frames[lemma][part_of_speech].map do |arguments, token_ids|
            { arguments: arguments, tokens: token_ids }
          end
        PROIEL::Valency::Obliqueness.sort_frames(frames)
      end

      private

      # Find verbal nodes in a sentence
      def find_verbal_nodes(sentence)
        sentence.tokens.select do |token|
          # FIXME: is this test in the proiel library already?
          (token.part_of_speech and token.part_of_speech[/^V/]) or token.empty_token_sort == 'V'
        end
      end
    end
  end
end
