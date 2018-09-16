#--
# Copyright (c) 2018 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
module PROIEL
  class Lemma < TreebankObject
    # @return [Dictionary] source that the lemma belongs to
    attr_reader :dictionary

    attr_reader :n

    # @return [Hash{String, Integer}] distribution of lemmata in sources. The
    # keys are IDs of sources, the values give the frequency of the lemma per
    # source.
    attr_reader :distribution

    # @return [Array<[String, String]> identified homographs of this lemma. The
    # array contains pairs of lemma form (which will be homographs of this
    # lemma form under the orthographic conventions of the language) and parts
    # of speech.
    attr_reader :homographs

    # @return [Hash{Symbol, String}] glosses for the current lemma. The keys
    # are language tags and the values the glosses.
    attr_reader :glosses
    attr_reader :paradigm
    attr_reader :valency

    # Creates a new lemma object.
    def initialize(parent, xml = nil)
      @dictionary = parent

      @n = nil

      @distribution = {}
      @homographs = []
      @glosses = {}
      @paradigm = {}
      @valency = []

      from_xml(xml) if xml
    end

    private

    def from_xml(xml)
      @n =  nullify(xml.n, :int)

      @distribution = xml.distribution.map { |h| [h.idref, nullify(h.n, :int)] }.to_h
      @glosses = xml.glosses.map { |h| [h.language.to_sym, h.gloss] }.to_h
      @homographs = xml.homographs.map { |h| [h.lemma, h.part_of_speech] }
      @paradigm = xml.paradigm.map { |slot1| [slot1.morphology, slot1.slot2s.map { |slot2| [slot2.form, nullify(slot2.n, :int)] }.to_h] }.to_h
      @valency =
        xml.valency.map do |frame|
          {
            arguments: frame.arguments.map { |a| { relation: a.relation, lemma: a.lemma, part_of_speech: a.part_of_speech, mood: a.mood, case: a.case } },
            tokens: frame.tokens.map { |t| { flags: t.flags, idref: t.idref  } },
          }
        end
    end

    def nullify(s, type = nil)
      case s
      when NilClass, /^\s*$/
        nil
      else
        case type
        when :int
          s.to_i
        else
          s.to_s
        end
      end
    end
  end
end

