#--
# Copyright (c) 2015-2016 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
require 'spec_helper'

describe PROIEL::PROIELXML::Schema do
  it 'returns the version number of the current PROIEL XML schema' do
    expect(PROIEL::PROIELXML::Schema.current_proiel_xml_schema_version).to match(/^\d\.\d$/)
  end

  it 'returns the filename of the a version of the PROIEL XML schema' do
    expect(PROIEL::PROIELXML::Schema.proiel_xml_schema_filename(PROIEL::PROIELXML::Schema.current_proiel_xml_schema_version)).to match(/proiel-\d\.\d\.xsd$/)
    expect(PROIEL::PROIELXML::Schema.proiel_xml_schema_filename('1.0')).to match(/proiel-1\.0\.xsd$/)
    expect(PROIEL::PROIELXML::Schema.proiel_xml_schema_filename('2.0')).to match(/proiel-2\.0\.xsd$/)
  end

  it 'detects an incorrect version of the PROIEL XML schema' do
    expect { PROIEL::PROIELXML::Schema.proiel_xml_schema_filename('X.0') }.to raise_error(ArgumentError)
  end

  it 'detects a PROIEL XML 2.0 file' do
    expect(PROIEL::PROIELXML::Schema.check_schema_version_of_xml_file(File.join(File.dirname(__FILE__), 'dummy-proiel-xml-2.0.xml'))).to eql('2.0')
  end

  it 'detects a PROIEL XML 2.1 file' do
    expect(PROIEL::PROIELXML::Schema.check_schema_version_of_xml_file(File.join(File.dirname(__FILE__), 'dummy-proiel-xml-2.1.xml'))).to eql('2.1')
  end

  it 'treats a PROIEL XML file without a schema version as a PROIEL XML 1.0 file' do
    expect(PROIEL::PROIELXML::Schema.check_schema_version_of_xml_file(File.join(File.dirname(__FILE__), 'proiel-xml-without-schema-version.xml'))).to eql('1.0')
  end

  it 'detects a PROIEL XML file with an invalid schema version' do
    expect { PROIEL::PROIELXML::Schema.check_schema_version_of_xml_file(File.join(File.dirname(__FILE__), 'proiel-xml-with-invalid-schema-version.xml')) }.to raise_error(RuntimeError)
  end

  it 'loads the the current PROIEL XML schema' do
    expect(PROIEL::PROIELXML::Schema.load_proiel_xml_schema(PROIEL::PROIELXML::Schema.current_proiel_xml_schema_version)).to be_instance_of(Nokogiri::XML::Schema)
  end
end
