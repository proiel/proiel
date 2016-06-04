#--
# Copyright (c) 2015-2016 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
require 'spec_helper'

describe PROIEL::Div do
  it 'returns an enumerator for sentences' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))
    o = tb.sources.first.divs.first

    expect(o.sentences.class).to eql(Enumerator)
    expect(o.sentences.count).to eql(5)
  end

  it 'returns an enumerator for tokens' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))
    o = tb.sources.first.divs.first

    expect(o.tokens.class).to eql(Enumerator)
    expect(o.tokens.count).to eql(119)
  end

  it 'has an inspect method' do
    t = PROIEL::Div.new(nil, 123, nil, nil, nil, nil)
    expect(t.inspect).to eql('#<PROIEL::Div @id=123>')
  end

  it 'provides title, presentation_before, presentation_after access' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first

    expect(div.id).to eql(1)
    expect(div.title).to eql("Caes., Gall. 1.1")
    expect(div.presentation_after).to eql(nil)
    expect(div.presentation_before).to eql(nil)
  end

  it 'provides access to parent objects' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first

    expect(div.source).to eql(source)
    expect(div.treebank).to eql(tb)
  end

  it 'provides access to sentences' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first

    expect(div.sentences.count).to eql(5)
    expect(div.sentences.first.class).to eql(PROIEL::Sentence)
  end

  it 'provides access to the language' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first

    expect(div.language).to eql('lat')
  end

  it 'generates a printable form' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first

    expect(div.printable_form).to eql('Gallia est omnis divisa in partes tres, quarum unam incolunt Belgae, aliam Aquitani, tertiam qui ipsorum lingua Celtae, nostra Galli appellantur.  Hi omnes lingua, institutis, legibus inter se differunt.  Gallos ab Aquitanis Garumna flumen, a Belgis Matrona et Sequana dividit.  Horum omnium fortissimi sunt Belgae, propterea quod a cultu atque humanitate provinciae longissime absunt, minimeque ad eos mercatores saepe commeant atque ea quae ad effeminandos animos pertinent important, proximique sunt Germanis, qui trans Rhenum incolunt, quibuscum continenter bellum gerunt. Qua de causa Helvetii quoque reliquos Gallos virtute praecedunt, quod fere cotidianis proeliis cum Germanis contendunt, cum aut suis finibus eos prohibent aut ipsi in eorum finibus bellum gerunt. ')
  end

  it 'generates a complete citation' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first

    expect(div.citation).to eql('Caes. Gal. 1.1.1–4')
  end
end
