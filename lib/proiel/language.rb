#--
# Copyright (c) 2019 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
module PROIEL
  module Language
    SUPPORTED_LANGUAGES = {
      # This is a subset of language codes from ISO 639-3 and Glottolog.
      ang: 'Old English (ca. 450-1100)',
      ave: 'Avestan',
      axm: 'Middle Armenian',
      chu: 'Church Slavic',
      cms: 'Messapic',
      cnx: 'Middle Cornish',
      dum: 'Middle Dutch',
      enm: 'Middle English',
      frk: 'Old Frankish',
      frm: 'Middle French',
      fro: 'Old French (842-ca. 1400)',
      ghc: 'Hiberno-Scottish Gaelic',
      gmh: 'Middle High German',
      gml: 'Middle Low German',
      gmy: 'Mycenaean Greek',
      goh: 'Old High German (ca. 750-1050)',
      got: 'Gothic',
      grc: 'Ancient Greek (to 1453)',
      hit: 'Hittite',
      hlu: 'Hieroglyphic Luwian',
      htx: 'Middle Hittite',
      lat: 'Latin',
      lng: 'Langobardic',
      mga: 'Middle Irish (10-12th century)',
      non: 'Old Norse',
      nrp: 'North Picene',
      obt: 'Old Breton',
      oco: 'Old Cornish',
      odt: 'Old Dutch-Old Frankish',
      ofs: 'Old Frisian',
      oht: 'Old Hittite',
      olt: 'Old Lithuanian',
      orv: 'Old Russian',
      osc: 'Oscan',
      osp: 'Old Spanish',
      osx: 'Old Saxon',
      owl: 'Old-Middle Welsh',
      peo: 'Old Persian (ca. 600-400 B.C.)',
      pka: 'Ardhamāgadhī Prākrit',
      pmh: 'Maharastri Prakrit',
      por: 'Portuguese',
      pro: 'Old Provençal',
      psu: 'Sauraseni Prakrit',
      rus: 'Russian',
      san: 'Sanskrit',
      sga: 'Early Irish',
      sog: 'Sogdian',
      spa: 'Spanish',
      spx: 'South Picene',
      txb: 'Tokharian B',
      txh: 'Thracian',
      wlm: 'Middle Welsh',
      xbm: 'Middle Breton',
      xcb: 'Cumbric',
      xce: 'Celtiberian',
      xcg: 'Cisalpine Gaulish',
      xcl: 'Classical Armenian',
      xum: 'Umbrian',
      xve: 'Venetic',
    }.freeze

    # Checks if a language is supported.
    #
    # @param language_tag [String, Symbol] language tag of language to check
    #
    # @return [Boolean]
    #
    # @example
    #   language_supported?(:lat)      # => true
    #   language_supported?('grc')     # => true
    def self.language_supported?(language_tag)
      raise ArgumentError unless language_tag.is_a?(Symbol) or language_tag.is_a?(String)

      SUPPORTED_LANGUAGES.key?(language_tag.to_sym)
    end

    # Returns the display name for a language.
    #
    # @param language_tag [String, Symbol] language tag of language
    #
    # @return [String]
    #
    # @example
    #   get_display_name(:lat)         # => "Latin"
    def self.get_display_name(language_tag)
      raise ArgumentError unless language_tag.is_a?(Symbol) or language_tag.is_a?(String)
      raise ArgumentError, 'unsupported language' unless language_supported?(language_tag)

      SUPPORTED_LANGUAGES[language_tag.to_sym]
    end

    # Returns tag of all supported languages
    #
    # @return [Array<Symbol>]
    def self.supported_language_tags
      SUPPORTED_LANGUAGES.keys
    end
  end
end
