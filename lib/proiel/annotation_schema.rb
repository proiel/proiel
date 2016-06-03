#--
# Copyright (c) 2015-2016 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
module PROIEL
  # A representation of the annotation schema found in the header of a PROIEL
  # XML file. This should not be confused with the PROIEL XML schema, which is
  # used for validating the XML in a PROIEL XML file.
  class AnnotationSchema
    # @return [Hash<String,PartOfSpeechTagDefinition>] definition of part of speech tags
    attr_reader :part_of_speech_tags

    # @return [Hash<String,RelationTagDefinition>] definition of relation tags
    attr_reader :relation_tags

    # @return [Hash<Symbol,Hash<String,MorphologyFieldTagDefinition>>] definition of morphology tags
    attr_reader :morphology_tags

    # @return [Hash<String,InformationStatusTagDefinition>] definition of information status tags
    attr_reader :information_status_tags

    # Creates a new annotation schema object.
    def initialize(xml_object)
      if xml_object
        @part_of_speech_tags = make_part_of_speech_tags(xml_object).freeze
        @relation_tags = make_relation_tags(xml_object).freeze
        @morphology_tags = make_morphology_tags(xml_object).freeze
        @information_status_tags = make_information_status_tags(xml_object).freeze
      else
        @part_of_speech_tags = {}
        @relation_tags = {}
        @morphology_tags = {}
        @information_status_tags = {}
      end
    end

    # @return [Hash<String,RelationTagDefinition>] definition of primary relation tags
    def primary_relations
      @relation_tags.select { |_, features| features.primary }
    end

    # @return [Hash<String,RelationTagDefinition>] definition of secondary relation tags
    def secondary_relations
      @relation_tags.select { |_, features| features.secondary }
    end

    # Tests for equality of two annotation schema objects.
    #
    # @return [true,false]
    #
    def ==(o)
      @part_of_speech_tags.sort_by(&:first) == o.part_of_speech_tags.sort_by(&:first) and
        @relation_tags.sort_by(&:first) == o.relation_tags.sort_by(&:first)
    end

    private

    def make_tag_hash(element)
      element.values.map { |e| [e.tag, yield(e)] }.compact.to_h
    end

    def make_relation_tags(xml_object)
      make_tag_hash(xml_object.relations) do |e|
        RelationTagDefinition.new(e.summary, e.primary == 'true', e.secondary == 'true')
      end
    end

    def make_part_of_speech_tags(xml_object)
      make_tag_hash(xml_object.parts_of_speech) do |e|
        PartOfSpeechTagDefinition.new(e.summary)
      end
    end

    def make_morphology_tags(xml_object)
      xml_object.morphology.fields.map do |f|
        v =
          make_tag_hash(f) do |e|
            MorphologyFieldTagDefinition.new(e.summary)
          end
        [f.tag, v]
      end.to_h
    end

    def make_information_status_tags(xml_object)
      make_tag_hash(xml_object.information_statuses) do |e|
        InformationStatusTagDefinition.new(e.summary)
      end
    end
  end

  # A tag definitions.
  #
  # @abstract
  class GenericTagDefinition
    attr_reader :summary

    def initialize(summary)
      @summary = summary
    end

    # Tests equality of two tag definitions.
    def ==(o)
      @summary == o.summary
    end
  end

  # Definition of an information status tag.
  class InformationStatusTagDefinition < GenericTagDefinition; end

  # Definition of a relation tag.
  class RelationTagDefinition < GenericTagDefinition
    attr_reader :primary
    attr_reader :secondary

    def initialize(summary, primary, secondary)
      super(summary)

      @primary = primary
      @secondary = secondary
    end

    # Tests equality of two tag definitions.
    def ==(o)
      @summary == o.summary and @primary == o.primary and @secondary == o.secondary
    end
  end

  # Definition of a morphology field tag.
  class MorphologyFieldTagDefinition < GenericTagDefinition; end

  # Definition of a part of speech tag.
  class PartOfSpeechTagDefinition < GenericTagDefinition; end
end
