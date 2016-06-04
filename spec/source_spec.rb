#--
# Copyright (c) 2015-2016 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
require 'spec_helper'

describe PROIEL::Source do
  it 'returns an enumerator for divs' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))
    o = tb.sources.first

    expect(o.divs.class).to eql(Enumerator)
    expect(o.divs.count).to eql(1)
  end

  it 'returns an enumerator for sentences' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))
    o = tb.sources.first

    expect(o.sentences.class).to eql(Enumerator)
    expect(o.sentences.count).to eql(5)
  end

  it 'returns an enumerator for tokens' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))
    o = tb.sources.first

    expect(o.tokens.class).to eql(Enumerator)
    expect(o.tokens.count).to eql(119)
  end

  it 'has an inspect method' do
    t = PROIEL::Source.new(nil, 'foobar', DateTime.now.to_s, nil, nil, nil)
    expect(t.inspect).to eql('#<PROIEL::Source @id="foobar">')
  end

  it 'provides id, language and metadata access' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    expect(tb.sources.count).to eql(1)
    expect(tb.sources.first.class).to eql(PROIEL::Source)
    expect(tb.sources.first.divs.count).to eql(1)
    expect(tb.sources.first.divs.first.class).to eql(PROIEL::Div)
  end

  it 'provides access to parent object' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first

    expect(source.treebank).to eql(tb)
  end

  it 'provides access to divs' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    expect(tb.sources.count).to eql(1)
    expect(tb.sources.first.class).to eql(PROIEL::Source)
    expect(tb.sources.first.divs.count).to eql(1)
    expect(tb.sources.first.divs.first.class).to eql(PROIEL::Div)
  end

  it 'generates a complete citation' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first

    expect(source.citation).to eql('Caes. Gal.')
  end

  it 'generates a printable form' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first

    expect(source.printable_form).to eql('Gallia est omnis divisa in partes tres, quarum unam incolunt Belgae, aliam Aquitani, tertiam qui ipsorum lingua Celtae, nostra Galli appellantur.  Hi omnes lingua, institutis, legibus inter se differunt.  Gallos ab Aquitanis Garumna flumen, a Belgis Matrona et Sequana dividit.  Horum omnium fortissimi sunt Belgae, propterea quod a cultu atque humanitate provinciae longissime absunt, minimeque ad eos mercatores saepe commeant atque ea quae ad effeminandos animos pertinent important, proximique sunt Germanis, qui trans Rhenum incolunt, quibuscum continenter bellum gerunt. Qua de causa Helvetii quoque reliquos Gallos virtute praecedunt, quod fere cotidianis proeliis cum Germanis contendunt, cum aut suis finibus eos prohibent aut ipsi in eorum finibus bellum gerunt. ')
  end
end
