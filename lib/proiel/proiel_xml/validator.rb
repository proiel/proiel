#--
# Copyright (c) 2015-2017 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
module PROIEL
  module PROIELXML
    # A validator object that uses an XML schema as well as additional
    # integrity checks to validate a PROIEL XML file. Functionality for
    # loading the XML schema and checking the PROIEL XML version number is
    # found in {PROIEL::PROIELXML::Schema}.
    class Validator
      # Returns an array of error messages generated during validation.
      attr_reader :errors

      # Creates a new validator for a PROIEL XML file.
      #
      # @param filename [String] name of PROIEL XML file to validate
      # @param aligned_filename [NilClass, String] name of PROIEL XML file to validate alignments against
      #
      def initialize(filename, aligned_filename = nil)
        @filename = filename
        @aligned_filename = aligned_filename
        @errors = []
      end

      # Checks if the PROIEL XML file is valid. This checks for
      # well-formedness, a valid schema version, validation against the schema
      # and referential integrity.
      #
      # If invalid, `errors` will contain error messages.
      #
      # @return [true, false]
      #
      def valid?
        wellformed? and valid_schema_version? and validates? and has_referential_integrity?
      end

      # Checks if the PROIEL XML file is well-formed XML.
      #
      # If not well-formed, an error message will be appended to `errors`.
      #
      # @return [true, false]
      #
      def wellformed?
        begin
          Nokogiri::XML(File.read(@filename)) { |config| config.strict }

          true
        rescue Nokogiri::XML::SyntaxError => _
          @errors << 'XML file is not wellformed'

          false
        end
      end

      # Checks if the PROIEL XML file has a valid schema version number.
      #
      # If invalid, an error message will be appended to `errors`.
      #
      # @return [true, false]
      #
      def valid_schema_version?
        schema_version = PROIEL::PROIELXML::Schema.check_schema_version_of_xml_file(@filename)

        if schema_version.nil?
          @errors << 'invalid schema version'

          false
        else
          true
        end
      rescue PROIEL::PROIELXML::Schema::InvalidSchemaVersion => e
        @errors << e.message

        false
      end

      # Checks if the PROIEL XML file validates against the schema.
      #
      # If invalid, error messages will be appended to `errors`.
      #
      # @return [true, false]
      #
      def validates?
        doc = Nokogiri::XML(File.read(@filename))

        schema_version = PROIEL::PROIELXML::Schema.check_schema_version_of_xml_file(@filename)

        schema = PROIEL::PROIELXML::Schema.load_proiel_xml_schema(schema_version)
        r = schema.validate(doc)

        if r.empty?
          true
        else
          @errors += r.map { |e| "Line #{e.line}: #{e.message}" }

          false
        end
      end

      # Checks the referential integrity of the PROIEL XML file.
      #
      # If inconsistencies are found, error messages will be appended to `errors`.
      #
      # @return [true, false]
      #
      def has_referential_integrity?
        tb = PROIEL::Treebank.new
        tb.load_from_xml(@filename)

        errors = []

        # Pass 1: keep track of all object IDs and look for duplicates
        sentence_ids = {}
        token_ids = {}

        tb.sources.each do |source|
          source.divs.each do |div|
            div.sentences.each do |sentence|
              errors << "Repeated sentence ID #{sentence.id}" if sentence_ids.key?(sentence.id)
              sentence_ids[sentence.id] = true

              sentence.tokens.each do |token|
                errors << "Repeated token ID #{token.id}" if token_ids.key?(token.id)
                token_ids[token.id] = { sentence: sentence.id, div: div.id, source: source.id }
              end
            end
          end
        end

        # Pass 2: check object ID references
        tb.sources.each do |source|
          source.tokens.each do |token|
            # Head IDs and slash IDs should be sentence internal
            check_reference_locality(errors, token, token_ids, :head_id, token.head_id, domain: :sentence, allow_nil: true)

            token.slashes.each do |_, target_id|
              check_reference_locality(errors, token, token_ids, :slash_id, target_id, domain: :sentence, allow_nil: false)
            end

            # Antecedent IDs should be source internal
            check_reference_locality(errors, token, token_ids, :antecedent_id, token.antecedent_id, domain: :source, allow_nil: true)
          end
        end

        # Pass 3: verify that all features are defined
        # TBD

        # Pass 4: alignment_id on div, sentence or token requires an alignment_id on source
        tb.sources.each do |source|
          if source.alignment_id.nil?
            if source.divs.any?(&:alignment_id) or source.sentences.any?(&:alignment_id) or source.tokens.any?(&:alignment_id)
              errors << "Alignment ID(s) on divs, sentences or tokens without alignment ID on source"
            end
          end
        end

        # Pass 5: if div is aligned, sentences and tokens within should belong
        # to aligned div(s); if sentence aligned, tokens within should belong
        # to aligned sentence(s). Skip if no alignment_id on source (see pass
        # 4) or if aligned source not available.
        if @aligned_filename
          aligned_tb = PROIEL::Treebank.new
          aligned_tb.load_from_xml(@aligned_filename)

          tb.sources.each do |source|
            if source.alignment_id
              aligned_source = aligned_tb.find_source(source.alignment_id)

              if aligned_source
                check_alignment_integrity(errors, source, aligned_source)
              else
                errors << "Aligned source not available in treebank"
              end
            end
          end
        end

        # Decide if there were any errors
        if errors.empty?
          true
        else
          @errors += errors

          false
        end
      end

      private

      def check_reference_locality(errors, token, token_ids, attribute_name,
                                   attribute_value, domain: :sentence, allow_nil: false)
        if attribute_value
          referenced_token = token_ids[attribute_value]

          if referenced_token.nil?
            errors << "Token #{token.id}: #{attribute_name} references an unknown token"
          elsif referenced_token[domain] != token.send(domain).id
            errors << "Token #{token.id}: #{attribute_name} references a token in a different #{domain}"
          end
        elsif allow_nil
          # Everything is fine...
        else
          errors << "Token #{token.id}: #{attribute_name} is null"
        end
      end

      def check_alignment_integrity(errors, source, aligned_source)
        source.divs.each do |div|
          target_sentences =
            div.sentences.map do |sentence|
              target_tokens =
                sentence.tokens.select(&:alignment_id).map do |token|
                  # Check that target token exists in aligned source
                  aligned_token = aligned_source.treebank.find_token(token.alignment_id)

                  if aligned_token
                    aligned_token
                  else
                    errors << "Token #{token.id}: aligned to token #{aligned_source.id}:#{token.alignment_id} which does not exist"
                    nil
                  end
                end

              inferred_target_sentences = target_tokens.compact.map(&:sentence).sort_by(&:id).uniq

              if sentence.alignment_id
                a = sentence.alignment_id.to_s.split(',').sort.join(',')
                i = inferred_target_sentences.map(&:id).sort.join(',')

                # FIXME: handle i.empty? case, in which we have to use a and check that the objects exist
                if a != i
                  errors << "Sentence #{sentence.id}: aligned to sentence #{aligned_source.id}:#{a} but inferred alignment is #{aligned_source.id}:#{i}"
                end
              end

              inferred_target_sentences
            end

          inferred_target_divs = target_sentences.flatten.compact.map(&:div).uniq

          if div.alignment_id
            a = div.alignment_id.to_s.split(',').sort.join(',')
            i = inferred_target_divs.map(&:id).sort.join(',')

            # FIXME: handle i.empty? case, in which we have to use a and check that the objects exist
            if a != i
              errors << "Div #{div.id}: aligned to div #{aligned_source.id}:#{a} but inferred alignment is #{aligned_source.id}:#{i}"
            end
          end
        end
      end
    end
  end
end
