#--
# Copyright (c) 2015-2017 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
require 'spec_helper'

describe PROIEL::Sentence do
  it 'returns an enumerator for tokens' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))
    o = tb.sources.first.divs.first.sentences.first

    expect(o.tokens.class).to eql(Enumerator)
    expect(o.tokens.count).to eql(26)
  end

  it 'has an inspect method' do
    t = PROIEL::Sentence.new(nil, 123, :unannotated, nil, nil, nil, nil, nil, nil, nil)
    expect(t.inspect).to eql('#<PROIEL::Sentence @id=123>')
  end

  it 'provides id, status, presentation_before, presentation_after access' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first
    sentence = div.sentences.first

    expect(sentence.id).to eql(52548)
    expect(sentence.status).to eql(:reviewed)
    expect(sentence.presentation_after).to eql(' ')
    expect(sentence.presentation_before).to eql(nil)
  end

  it 'provides access to parent objects' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first
    sentence = div.sentences.first

    expect(sentence.div).to eql(div)
    expect(sentence.source).to eql(source)
    expect(sentence.treebank).to eql(tb)
  end

  it 'provides access to tokens' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first
    sentence = div.sentences.first

    expect(sentence.tokens.count).to eql(26)
    expect(sentence.tokens.first.class).to eql(PROIEL::Token)
  end

  it 'generates a complete citation' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first
    sentence = div.sentences.first

    expect(sentence.citation).to eql('Caes. Gal. 1.1.1')
  end

  it 'generates a printable form' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first
    sentence = div.sentences.first

    expect(sentence.printable_form).to eql('Gallia est omnis divisa in partes tres, quarum unam incolunt Belgae, aliam Aquitani, tertiam qui ipsorum lingua Celtae, nostra Galli appellantur.  ')

    formatter = lambda { |token|
      '1' + (token.form || '') + '1'
    }

    expect(sentence.printable_form(custom_token_formatter: formatter)).to eql '1Gallia1 1est1 1omnis1 1divisa1 1in1 1partes1 1tres1, 1quarum1 1unam1 1incolunt1 1Belgae1, 1aliam1 1Aquitani1, 1tertiam1 1qui1 1ipsorum1 1lingua1 1Celtae1, 1nostra1 1Galli1 1appellantur1.  '
  end

  it 'generates a syntax graph' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first
    sentence = div.sentences.first

    graph = { :id => nil, :relation => nil, :children => [{ :id => 680721, :relation => "pred", :children => [{ :id => 680720, :relation => "sub", :children => [{ :id => 680722, :relation => "atr", :children => [], :slashes => [] }], :slashes => [] }, { :id => 680723, :relation => "xobj", :children => [{ :id => 680724, :relation => "obl", :children => [{ :id => 680725, :relation => "obl", :children => [{ :id => 680726, :relation => "atr", :children => [], :slashes => [] }, { :id => 733299, :relation => "apos", :children => [{ :id => 680729, :relation => "apos", :children => [{ :id => 680728, :relation => "obj", :children => [{ :id => 680727, :relation => "part", :children => [], :slashes => [] }], :slashes => [] }, { :id => 680730, :relation => "sub", :children => [], :slashes => [] }], :slashes => [] }, { :id => 733300, :relation => "apos", :children => [{ :id => 680731, :relation => "obj", :children => [], :slashes => [] }, { :id => 680732, :relation => "sub", :children => [], :slashes => [] }], :slashes => [["pid", 680729]] }, { :id => 733301, :relation => "apos", :children => [{ :id => 680733, :relation => "obj", :children => [], :slashes => [] }, { :id => 733302, :relation => "sub", :children => [{ :id => 680740, :relation => "sub", :children => [{ :id => 680734, :relation => "sub", :children => [], :slashes => [] }, { :id => 680736, :relation => "adv", :children => [{ :id => 680735, :relation => "atr", :children => [], :slashes => [] }], :slashes => [] }, { :id => 680737, :relation => "xobj", :children => [], :slashes => [["xsub", 680734]] }], :slashes => [] }, { :id => 733303, :relation => "sub", :children => [{ :id => 680738, :relation => "adv", :children => [], :slashes => [] }, { :id => 680739, :relation => "xobj", :children => [], :slashes => [["xsub", 733303]] }], :slashes => [["sub", 680734], ["pid", 680740]] }], :slashes => [] }], :slashes => [["pid", 680729]] }], :slashes => [] }], :slashes => [] }], :slashes => [] }], :slashes => [["xsub", 680720]] }], :slashes => [] }], :slashes => [] }

    expect(sentence.syntax_graph).to eql(graph)
  end

  it 'generates syntax graphs' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first
    sentence = div.sentences.first

    graphs = [{ :id => 680721, :relation => "pred", :children => [{ :id => 680720, :relation => "sub", :children => [{ :id => 680722, :relation => "atr", :children => [], :slashes => [] }], :slashes => [] }, { :id => 680723, :relation => "xobj", :children => [{ :id => 680724, :relation => "obl", :children => [{ :id => 680725, :relation => "obl", :children => [{ :id => 680726, :relation => "atr", :children => [], :slashes => [] }, { :id => 733299, :relation => "apos", :children => [{ :id => 680729, :relation => "apos", :children => [{ :id => 680728, :relation => "obj", :children => [{ :id => 680727, :relation => "part", :children => [], :slashes => [] }], :slashes => [] }, { :id => 680730, :relation => "sub", :children => [], :slashes => [] }], :slashes => [] }, { :id => 733300, :relation => "apos", :children => [{ :id => 680731, :relation => "obj", :children => [], :slashes => [] }, { :id => 680732, :relation => "sub", :children => [], :slashes => [] }], :slashes => [["pid", 680729]] }, { :id => 733301, :relation => "apos", :children => [{ :id => 680733, :relation => "obj", :children => [], :slashes => [] }, { :id => 733302, :relation => "sub", :children => [{ :id => 680740, :relation => "sub", :children => [{ :id => 680734, :relation => "sub", :children => [], :slashes => [] }, { :id => 680736, :relation => "adv", :children => [{ :id => 680735, :relation => "atr", :children => [], :slashes => [] }], :slashes => [] }, { :id => 680737, :relation => "xobj", :children => [], :slashes => [["xsub", 680734]] }], :slashes => [] }, { :id => 733303, :relation => "sub", :children => [{ :id => 680738, :relation => "adv", :children => [], :slashes => [] }, { :id => 680739, :relation => "xobj", :children => [], :slashes => [["xsub", 733303]] }], :slashes => [["sub", 680734], ["pid", 680740]] }], :slashes => [] }], :slashes => [["pid", 680729]] }], :slashes => [] }], :slashes => [] }], :slashes => [] }], :slashes => [["xsub", 680720]] }], :slashes => [] }]

    expect(sentence.syntax_graphs).to eql(graphs)
  end

  it 'provides access to the language' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first
    sentence = div.sentences.first

    expect(sentence.language).to eql('lat')
  end

  it 'provides access to {annotated,reviewed}_{by,at}' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.1.xml'))

    source = tb.sources.first
    div = source.divs.first
    sentence = div.sentences.first

    expect(sentence.annotated_by).to eql('john')
    expect(sentence.reviewed_by).to eql('mary')
    expect(sentence.annotated_at).to eql(DateTime.xmlschema("2016-06-04T16:35:30+01:00"))
    expect(sentence.reviewed_at).to eql(DateTime.xmlschema("2016-06-04T16:35:30+01:00"))
  end
end
