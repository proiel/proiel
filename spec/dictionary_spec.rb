#--
# Copyright (c) 2018 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
require 'spec_helper'

describe PROIEL::Dictionary do
  it 'has an inspect method' do
    t = PROIEL::Dictionary.new(nil, DateTime.now.to_s, 'orv', nil, nil)
    expect(t.inspect).to eql('#<PROIEL::Dictionary @id="orv">')
  end

  it 'provides language, dialect access' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('data/proielxml-3.0-skeleton.xml'))

    expect(tb.dictionaries.count).to eql(1)

    d = tb.dictionaries.first

    expect(d.class).to eql(PROIEL::Dictionary)
    expect(d.language).to eql('non')
    expect(d.dialect).to eql('swe')
  end

  it 'provides access to parent object' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('data/proielxml-3.0-skeleton.xml'))

    d = tb.dictionaries.first

    expect(d.treebank).to eql(tb)
  end

  it 'provides access to source references' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('data/proielxml-3.0-skeleton.xml'))

    d = tb.dictionaries.first
    s = d.sources

    expect(s.class).to eql(Hash)

    expect(s.key?('afnik')).to eql(true)
    expect(s['afnik'][:license]).to eql('CC SA-BY-NC 4.0')
    expect(s['afnik'][:n]).to eql(10)

    expect(s.key?('avv')).to eql(true)
    expect(s['avv'][:license]).to eql(nil)
    expect(s['avv'][:n]).to eql(nil)

    expect(s.key?('avv')).to eql(true)
    expect(s['birchbark'][:license]).to eql(nil)
    expect(s['birchbark'][:n]).to eql(nil)
  end

  it 'provides access to lemma definitions' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('data/proielxml-3.0-skeleton.xml'))

    d = tb.dictionaries.first
    l = d.lemmata

    expect(l.class).to eql(Hash)

    expect(l.key?('а')).to eql(true)
    expect(l['а'].key?('C-')).to eql(true)
    expect(l['а']['C-'].n).to eql(2971)

    expect(l.key?('благодарити')).to eql(true)
    expect(l['благодарити'].key?('V-')).to eql(true)
    expect(l['благодарити']['V-'].n).to eql(nil)
  end

  it 'provides access to homographs' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('data/proielxml-3.0-skeleton.xml'))

    d = tb.dictionaries.first
    l = d.lemmata['а']['C-']

    expect(l.homographs.count).to eql(2)
    expect(l.homographs[0]).to eql(['а', 'F-'])
    expect(l.homographs[1]).to eql(['а', 'Ne'])
  end

  it 'provides access to glosses' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('data/proielxml-3.0-skeleton.xml'))

    d = tb.dictionaries.first
    l = d.lemmata['благодарити']['V-']

    expect(l.glosses.count).to eql(2)
    expect(l.glosses[:eng]).to eql('thank')
  end

  it 'provides access to distribution' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('data/proielxml-3.0-skeleton.xml'))

    d = tb.dictionaries.first
    l = d.lemmata['благодарити']['V-']

    expect(l.distribution.count).to eql(4)
    expect(l.distribution['suz-lav']).to eql(1)
  end

  it 'provides access to paradigm' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('data/proielxml-3.0-skeleton.xml'))

    d = tb.dictionaries.first
    l = d.lemmata['благодарити']['V-']

    expect(l.paradigms.count).to eql(8)
    expect(l.paradigms['--pna----i'].count).to eql(1)
    expect(l.paradigms['--pna----i']['бл҃годарити']).to eql(1)

    expect(l.paradigms['3siia----i'].count).to eql(2)
    expect(l.paradigms['3siia----i']['бл҃годарѧше']).to eql(3)
    expect(l.paradigms['3siia----i']['бл҃годарꙗше']).to eql(1)
  end

  it 'provides access to valency' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('data/proielxml-3.0-skeleton.xml'))

    d = tb.dictionaries.first
    l = d.lemmata['благодарити']['V-']

    expect(l.valency.count).to eql(7)
    expect(l.valency[1][:arguments].count).to eql(1)
    expect(l.valency[1][:arguments][0]).to eql({:relation=>"obj", :lemma=>nil, :part_of_speech=>nil, :mood=>nil, :case=>"a"})
    expect(l.valency[1][:tokens].count).to eql(1)

    expect(l.valency[1][:tokens][0][:flags]).to eql('a')
    expect(l.valency[1][:tokens][0][:n]).to eql(4)
    expect(l.valency[1][:tokens][0][:tokens].count).to eql(4)
    expect(l.valency[1][:tokens][0][:tokens]).to eql(['2185961', '2188457', '2217926', '2160424'])
  end
end
