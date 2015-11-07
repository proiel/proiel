#--
# Copyright (c) 2015-2018 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
require 'spec_helper'

describe PROIEL::PROIELXML::Validator do
  it 'detects a valid PROIEL XML file' do
    @v = PROIEL::PROIELXML::Validator.new(File.join(File.dirname(__FILE__), 'data/proielxml-2.0-skeleton.xml'))
    expect(@v.valid?).to eql(true)

    @v = PROIEL::PROIELXML::Validator.new(File.join(File.dirname(__FILE__), 'data/proielxml-2.1-skeleton.xml'))
    expect(@v.valid?).to eql(true)

    @v = PROIEL::PROIELXML::Validator.new(File.join(File.dirname(__FILE__), 'data/proielxml-3.0-skeleton.xml'))
    expect(@v.valid?).to eql(true)
  end

  it 'does not report errors when it detects a valid PROIEL XML file' do
    @v = PROIEL::PROIELXML::Validator.new(File.join(File.dirname(__FILE__), 'data/proielxml-2.0-skeleton.xml'))
    @v.valid?
    expect(@v.errors.empty?).to eql(true)

    @v = PROIEL::PROIELXML::Validator.new(File.join(File.dirname(__FILE__), 'data/proielxml-2.1-skeleton.xml'))
    @v.valid?
    expect(@v.errors.empty?).to eql(true)

    @v = PROIEL::PROIELXML::Validator.new(File.join(File.dirname(__FILE__), 'data/proielxml-3.0-skeleton.xml'))
    @v.valid?
    expect(@v.errors.empty?).to eql(true)
  end

  it 'detects a PROIEL XML file with an invalid schema version' do
    @v = PROIEL::PROIELXML::Validator.new(File.join(File.dirname(__FILE__), 'data/proielxml-invalid-version-minimal.xml'))

    expect(@v.valid?).to eql(false)
  end

  it 'reports errors when it detects a PROIEL XML file with an invalid schema version' do
    @v = PROIEL::PROIELXML::Validator.new(File.join(File.dirname(__FILE__), 'data/proielxml-invalid-version-minimal.xml'))
    @v.valid?

    expect(@v.errors.length).to eql(1)
    expect(@v.errors.first).to eql('invalid schema version number')
  end

  it 'detects lack of referential integrity in a PROIEL XML file' do
    @v = PROIEL::PROIELXML::Validator.new(File.join(File.dirname(__FILE__), 'data/proielxml-2.0-inconsistent.xml'))

    expect(@v.valid?).to eql(false)
  end

  it 'reports errors when it detects an invalid antecedent reference' do
    @v = PROIEL::PROIELXML::Validator.new(File.join(File.dirname(__FILE__), 'data/proielxml-2.0-inconsistent.xml'))
    @v.valid?

    expect(@v.errors.length).to eql(1)
    expect(@v.errors.first).to eql('Token 1084259: antecedent_id references an unknown token')

    @v = PROIEL::PROIELXML::Validator.new(File.join(File.dirname(__FILE__), 'data/proielxml-2.1-inconsistent.xml'))
    @v.valid?

    expect(@v.errors.length).to eql(2)
    expect(@v.errors.first).to eql('Token 1084259: antecedent_id references an unknown token')
  end

  it 'reports errors when it detects alignment IDs on divs, sentences or tokens without alignment IDs on sources' do
    @v = PROIEL::PROIELXML::Validator.new(File.join(File.dirname(__FILE__), 'data/proielxml-2.1-inconsistent.xml'))
    @v.valid?

    expect(@v.errors.length).to eql(2)
    expect(@v.errors.last).to eql('Alignment ID(s) on divs, sentences or tokens without alignment ID on source')
  end
end
