#--
# Copyright (c) 2015 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
require 'spec_helper'

describe PROIEL::PROIELXML::Validator do
  it 'detects a valid PROIEL XML file' do
    @v = PROIEL::PROIELXML::Validator.new(File.join(File.dirname(__FILE__), 'dummy-proiel-xml-2.0.xml'))

    expect(@v.valid?).to eql(true)
  end

  it 'does not report errors when it detects a valid PROIEL XML file' do
    @v = PROIEL::PROIELXML::Validator.new(File.join(File.dirname(__FILE__), 'dummy-proiel-xml-2.0.xml'))
    @v.valid?

    expect(@v.errors.empty?).to eql(true)
  end

  it 'detects a PROIEL XML file with an invalid schema version' do
    @v = PROIEL::PROIELXML::Validator.new(File.join(File.dirname(__FILE__), 'proiel-xml-with-invalid-schema-version.xml'))

    expect(@v.valid?).to eql(false)
  end

  it 'reports errors when it detects a PROIEL XML file with an invalid schema version' do
    @v = PROIEL::PROIELXML::Validator.new(File.join(File.dirname(__FILE__), 'proiel-xml-with-invalid-schema-version.xml'))
    @v.valid?

    expect(@v.errors.length).to eql(1)
    expect(@v.errors.first).to eql('invalid schema version number')
  end

  it 'detects lack of referential integrity in a PROIEL XML file' do
    @v = PROIEL::PROIELXML::Validator.new(File.join(File.dirname(__FILE__), 'inconsistent-proiel-xml-2.0.xml'))

    expect(@v.valid?).to eql(false)
  end

  it 'reports errors when it detects lack of referential integrity in a PROIEL XML file' do
    @v = PROIEL::PROIELXML::Validator.new(File.join(File.dirname(__FILE__), 'inconsistent-proiel-xml-2.0.xml'))
    @v.valid?

    expect(@v.errors.length).to eql(1)
    expect(@v.errors.first).to eql('Token 1171944: antecedent_id references an unknown token')
  end
end
