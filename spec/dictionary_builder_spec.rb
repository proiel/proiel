require 'spec_helper'
require 'stringio'

describe PROIEL::DictionaryBuilder do
  let(:tb) do
    tb = PROIEL::Treebank.new
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))
    tb
  end

  let(:source) { tb.sources.first }

  describe '#add_source!' do
    it 'adds a source and indexes tokens' do
      builder = PROIEL::DictionaryBuilder.new
      builder.add_source!(source)

      expect(builder.sources).to include(source)
      expect(builder.language).to eq(source.language)

      # Check for a known lemma from dummy-proiel-xml-2.0.xml
      # Sentence 52548: Gallia est omnis divisa ...
      # Gallia: lemma=Gallia, pos=Ne
      expect(builder.lemmata.keys).to include('Gallia,Ne')
      expect(builder.lemmata['Gallia,Ne'][:n]).to be > 0
    end
  end

  describe '#to_xml' do
    it 'generates XML output' do
      builder = PROIEL::DictionaryBuilder.new
      builder.add_source!(source)

      io = StringIO.new
      builder.to_xml(io)
      xml = io.string

      expect(xml).to include('<dictionary')
      expect(xml).to include('language="lat"')
      expect(xml).to include('<lemma lemma="Gallia" part-of-speech="Ne">')
    end
  end
end
