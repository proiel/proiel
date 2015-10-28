#--
# Copyright (c) 2015 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
require 'spec_helper'

describe PROIEL::Treebank do
  it 'creates a new, empty Treebank object' do
    tb = PROIEL::Treebank.new()

    expect(tb.sources.count).to eql(0)
    expect(tb.annotation_schema).to eql(nil)
    expect(tb.schema_version).to eql(nil)
  end

  it 'loads a single source' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    expect(tb.sources.count).to eql(1)
    expect(tb.sources.first.class).to eql(PROIEL::Source)
    expect(tb.sources.first.id).to eql('caes-gal')
    expect(tb.annotation_schema.class).to eql(PROIEL::AnnotationSchema)
    expect(tb.schema_version).to eql('2.0')
  end

  it 'loads multiple sources from a single file' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('multiple-sources.xml'))

    expect(tb.sources.count).to eql(2)
    expect(tb.sources[0].class).to eql(PROIEL::Source)
    expect(tb.sources[0].id).to eql('caes-gal')
    expect(tb.sources[1].class).to eql(PROIEL::Source)
    expect(tb.sources[1].id).to eql('cic-att')
    expect(tb.annotation_schema.class).to eql(PROIEL::AnnotationSchema)
    expect(tb.schema_version).to eql('2.0')
  end

  it 'compares identical schemas' do
    tb1 = PROIEL::Treebank.new()
    tb1.load_from_xml(test_file('multiple-sources.xml'))

    tb2 = PROIEL::Treebank.new()
    tb2.load_from_xml(test_file('multiple-sources.xml'))

    expect(tb1.annotation_schema.class).to eql(PROIEL::AnnotationSchema)
    expect(tb2.annotation_schema.class).to eql(PROIEL::AnnotationSchema)

    expect(tb1.schema_version).to eql('2.0')
    expect(tb2.schema_version).to eql('2.0')

    expect(tb1.annotation_schema == tb2.annotation_schema).to eql(true)
    expect(tb2.schema_version == tb2.schema_version).to eql(true)
  end

  it 'looks up objects in the object index' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    expect(tb.find_token(680720).id).to eql(680720)
    expect(tb.find_sentence(52548).id).to eql(52548)
    expect(tb.find_div(1).id).to eql(1)
    expect(tb.find_source('caes-gal').id).to eql('caes-gal')
  end
end
