#--
# Copyright (c) 2018 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
module PROIEL
  class Dictionary < TreebankObject
    # @return [Treebank] treebank that this source belongs to
    attr_reader :treebank

    # @return [String] language of the source as an ISO 639-3 language tag
    attr_reader :language

    # @return [String] dialect of the source
    attr_reader :dialect

    # @return [DateTime] export time for the dictionary
    attr_reader :export_time

    # @return [Hash] all lemmata in the dictionary
    attr_reader :lemmata

    # @return [Integer] number of lemmata in the dictionary
    attr_reader :n

    # @return [Hash] all sources in the dictionary
    attr_reader :sources

    # Creates a new dictionary object.
    def initialize(parent, export_time, language, dialect, xml = nil)
      @treebank = parent

      raise ArgumentError, 'string or nil expected' unless export_time.nil? or export_time.is_a?(String)
      @export_time = export_time.nil? ? nil : DateTime.parse(export_time).freeze

      @language = language.freeze
      @dialect = dialect ? dialect.freeze : nil

      @lemmata = {}
      @sources = {}
      @n = 0

      from_xml(xml) if xml
    end

    # FIXME
    def id
      @language
    end

    private

    def from_xml(xml)
      xml.sources.each do |s|
        @sources[s.idref] = { license: nullify(s.license), n: nullify(s.n, :int) }
      end

      xml.lemmata.each do |l|
        @lemmata[l.lemma] ||= {}
        @lemmata[l.lemma][l.part_of_speech] = Lemma.new(self, l)
        @n += 1
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
