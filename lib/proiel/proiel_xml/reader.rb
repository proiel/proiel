#--
# Copyright (c) 2015-2016 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
module PROIEL
  module PROIELXML
    # @api private
    module Reader
      # Parsing class for `slash` elements.
      class Slash
        include SAXMachine

        attribute :'target-id', as: :target_id, class: Integer, required: true
        attribute :relation, required: true
      end

      # Parsing class for `token` elements.
      class Token
        include SAXMachine

        attribute :id, class: Integer, required: true
        attribute :'alignment-id', as: :alignment_id, class: Integer, required: false
        attribute :'head-id', as: :head_id, class: Integer
        attribute :form
        attribute :lemma
        attribute :'part-of-speech', as: :part_of_speech
        attribute :morphology
        attribute :relation
        attribute :'empty-token-sort', as: :empty_token_sort
        attribute :'citation-part', as: :citation_part
        attribute :'presentation-before', as: :presentation_before
        attribute :'presentation-after', as: :presentation_after
        attribute :'antecedent-id', as: :antecedent_id, class: Integer
        attribute :'information-status', as: :information_status
        attribute :'contrast-group', as: :contrast_group
        attribute :'foreign-ids', as: :foreign_ids

        elements :slash, as: :slashes, class: Slash
      end

      # Parsing class for `sentence` elements.
      class Sentence
        include SAXMachine

        attribute :id, class: Integer, required: true
        attribute :'alignment-id', as: :alignment_id, class: Integer, required: false
        attribute :status, class: Symbol, default: :unannotated
        attribute :'annotated-by', as: :annotated_by, required: false
        attribute :'reviewed-by', as: :reviewed_by, required: false
        attribute :'annotated-at', as: :annotated_at, required: false
        attribute :'reviewed-at', as: :reviewed_at, required: false
        attribute :'presentation-before', as: :presentation_before
        attribute :'presentation-after', as: :presentation_after

        elements :token, as: :tokens, class: Token
      end

      # Parsing class for `div` elements.
      class Div
        include SAXMachine

        attribute :id, class: Integer, required: false
        attribute :'alignment-id', as: :alignment_id, class: Integer, required: false
        attribute :'presentation-before', as: :presentation_before
        attribute :'presentation-after', as: :presentation_after

        element :title
        elements :sentence, as: :sentences, class: Sentence
      end

      # Parsing class for `source` elements.
      class Source
        include SAXMachine

        attribute :id, required: true
        attribute :'alignment-id', as: :alignment_id, required: false
        attribute :language, required: true

        element :title
        element :author
        element :citation_part
        element :principal
        element :funder
        element :distributor
        element :distributor_address
        element :date
        element :license
        element :license_url
        element :reference_system
        element :editor
        element :editorial_note
        element :annotator
        element :reviewer
        element :electronic_text_editor
        element :electronic_text_title
        element :electronic_text_version
        element :electronic_text_publisher
        element :electronic_text_place
        element :electronic_text_date
        element :electronic_text_original_url
        element :electronic_text_license
        element :electronic_text_license_url
        element :printed_text_editor
        element :printed_text_title
        element :printed_text_edition
        element :printed_text_publisher
        element :printed_text_place
        element :printed_text_date
        elements :div, as: :divs, class: Div
      end

      # Parsing class for `relations/value` elements.
      class RelationValue
        include SAXMachine

        attribute :tag, required: true
        attribute :summary, required: true
        attribute :primary, required: true
        attribute :secondary, required: true
      end

      # Parsing class for `relations` elements.
      class Relations
        include SAXMachine

        elements :value, as: :values, class: RelationValue
      end

      # Parsing class for `parts_of_speech/value` elements.
      class PartOfSpeechValue
        include SAXMachine

        attribute :tag, required: true
        attribute :summary, required: true
      end

      # Parsing class for `parts_of_speech` elements.
      class PartsOfSpeech
        include SAXMachine

        elements :value, as: :values, class: PartOfSpeechValue
      end

      # Parsing class for `morphology/field/value` elements.
      class MorphologyValue
        include SAXMachine

        attribute :tag, required: true
        attribute :summary, required: true
      end

      # Parsing class for `morphology/field` elements.
      class MorphologyField
        include SAXMachine

        attribute :tag, required: true

        elements :value, as: :values, class: MorphologyValue
      end

      # Parsing class for `morphology` elements.
      class Morphology
        include SAXMachine

        elements :field, as: :fields, class: MorphologyField
      end

      # Parsing class for `information_statuses/value` elements.
      class InformationStatusValue
        include SAXMachine

        attribute :tag, required: true
        attribute :summary, required: true
      end

      # Parsing class for `information_statuses` elements.
      class InformationStatuses
        include SAXMachine

        elements :value, as: :values, class: InformationStatusValue
      end

      # Parsing class for `annotation` elements.
      class Annotation
        include SAXMachine

        element :relations, class: Relations
        element :parts_of_speech, as: :parts_of_speech, class: PartsOfSpeech
        element :morphology, class: Morphology
        element :information_statuses, as: :information_statuses, class: InformationStatuses
      end

      # Parsing class for `proiel` elements.
      class Proiel
        include SAXMachine

        attribute :'export-time', as: :export_time
        attribute :'schema-version', as: :schema_version, required: true

        elements :source, as: :sources, class: Source
        element :annotation, class: Annotation
      end

      # Top-level parsing class for a PROIEL XML file.
      class TreebankFile
        include SAXMachine

        element :proiel, class: Proiel
      end

      # Parses PROIEL XML data.
      #
      # This does not automatically validate the PROIEL XML. If given an
      # invalid PROIEL XML file, parsing is likely to succeed but the returned
      # objects will be in an inconsistent state.
      #
      # @see parse_io
      #
      # @param xml [String] PROIEL XML to parse
      #
      # @return [TreebankFile]
      #
      def self.parse_xml(xml)
        TreebankFile.parse(xml)
      end

      # Parses a PROIEL XML file.
      #
      # This does not automatically validate the PROIEL XML. If given an
      # invalid PROIEL XML file, parsing is likely to succeed but the returned
      # objects will be in an inconsistent state.
      #
      # @see parse_xml
      #
      # @param io [IO] stream representing the PROIEL XML file
      #
      # @return [TreebankFile]
      #
      def self.parse_io(io)
        parse_xml(io.read)
      end
    end
  end
end
