#--
# Copyright (c) 2015 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
module PROIEL
  module PROIELXML
    # Functionality concerned with PROIEL XML schema loading and versioning.
    # Functionality for validation using a PROIEL XML schema is found in
    # {PROIEL::PROIELXML::Validator}.
    #
    # @api private
    module Schema
      # Returns the current version of the PROIEL XML schema.
      #
      # @return [String] schema version number
      #
      def self.current_proiel_xml_schema_version
        '2.1'
      end

      # Invalid PROIEL XML schema version error.
      #
      # This represents an error that occurs when an unknown PROIEL XML schema
      # version number is encountered or one that could not be parsed.
      class InvalidSchemaVersion < RuntimeError; end

      # Opens a PROIEL XML schema file and peek at the schema version number
      # that the file claims it conforms to.
      #
      # @return [String] schema version number
      #
      # @raise InvalidSchemaVersion
      #
      def self.check_schema_version_of_xml_file(filename)
        doc = Nokogiri::XML(File.read(filename))

        if doc and doc.root and doc.root.name == 'proiel'
          case doc.root.attr('schema-version')
          when '2.0'
            '2.0'
          when '2.1'
            '2.1'
          when NilClass
            '1.0'
          else
            raise InvalidSchemaVersion, 'invalid schema version number'
          end
        else
          raise InvalidSchemaVersion, 'top-level XML element not found'
        end
      end

      # Loads a PROIEL XML schema.
      #
      # @return [Nokogiri::XML::Schema] schema version number
      #
      # @raise RuntimeError
      #
      def self.load_proiel_xml_schema(schema_version)
        filename = proiel_xml_schema_filename(schema_version)

        Nokogiri::XML::Schema(File.open(filename).read)
      end

      # Determines the filename of a specific version of the PROIEL XML schema.
      #
      # @return [String] filename
      #
      # @raise ArgumentError
      #
      def self.proiel_xml_schema_filename(schema_version)
        if schema_version == '1.0' or schema_version == '2.0' or schema_version == '2.1'
          File.join(File.dirname(__FILE__),
                    "proiel-#{schema_version}",
                    "proiel-#{schema_version}.xsd")
        else
          raise ArgumentError, 'invalid schema version'
        end
      end
    end
  end
end
