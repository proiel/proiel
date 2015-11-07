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
    attr_reader :distribution
    attr_reader :homographs
    attr_reader :glosses
    attr_reader :paradigms
    attr_reader :valency

    # Creates a new lemma object.
    def initialize(parent, xml = nil)
      @dictionary = parent

      @n = nil

      @distribution = {}
      @homographs = []
      @glosses = {}
      @paradigms = {}
      @valency = []

      from_xml(xml) if xml
    end

    private

    def from_xml(xml)
      @n =  nullify(xml.n, :int)

      @distribution = xml.distribution.map { |h| [h.idref, nullify(h.n, :int)] }.to_h
      @glosses = xml.glosses.map { |h| [h.language.to_sym, h.gloss] }.to_h
      @homographs = xml.homographs.map { |h| [h.lemma, h.part_of_speech] }
      @paradigms = xml.paradigms.map { |slot1| [slot1.morphology, slot1.slot2s.map { |slot2| [slot2.form, nullify(slot2.n, :int)] }.to_h] }.to_h
      @valency =
        xml.valency.map do |frame|
          {
            arguments: frame.arguments.map { |a| { relation: a.relation, lemma: a.lemma, part_of_speech: a.part_of_speech, mood: a.mood, case: a.case } },
            tokens: frame.tokens.map { |ts| { n: nullify(ts.n, :int), flags: ts.flags, tokens: ts.tokens.map { |t| t.idref } } },
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

