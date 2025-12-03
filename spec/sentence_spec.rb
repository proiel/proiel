#--
# Copyright (c) 2015-2017 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
require 'spec_helper'

describe PROIEL::Sentence do
  let(:treebank) { PROIEL::Treebank.new.load_from_xml(test_file('dummy-proiel-xml-2.0.xml')) }
  let(:source) { treebank.sources.first }
  let(:div) { source.divs.first }
  let(:sentence) { div.sentences.first }

  describe '#inspect' do
    it 'returns a string representation' do
      t = PROIEL::Sentence.new(nil, 123, :unannotated, nil, nil, nil, nil, nil, nil, nil)
      expect(t.inspect).to eq('#<PROIEL::Sentence @id=123>')
    end
  end

  describe 'attributes' do
    subject { sentence }

    it 'provides basic attributes' do
      expect(subject.id).to eq(52548)
      expect(subject.status).to eq(:reviewed)
      expect(subject.presentation_after).to eq(' ')
      expect(subject.presentation_before).to be_nil
    end

    it 'provides access to parent objects' do
      expect(subject.div).to eq(div)
      expect(subject.source).to eq(source)
      expect(subject.treebank).to eq(treebank)
    end

    it 'provides access to language' do
      expect(subject.language).to eq('lat')
    end
  end

  describe '#tokens' do
    it 'returns an enumerator for tokens' do
      expect(sentence.tokens).to be_a(Enumerator)
      expect(sentence.tokens.count).to eq(26)
      expect(sentence.tokens.first).to be_a(PROIEL::Token)
    end
  end

  describe '#citation' do
    it 'generates a complete citation' do
      expect(sentence.citation).to eq('Caes. Gal. 1.1.1')
    end
  end

  describe '#printable_form' do
    it 'generates a printable form' do
      expect(sentence.printable_form).to eq('Gallia est omnis divisa in partes tres, quarum unam incolunt Belgae, aliam Aquitani, tertiam qui ipsorum lingua Celtae, nostra Galli appellantur.  ')
    end

    it 'generates a printable form with a custom formatter' do
      formatter = lambda { |token| '1' + (token.form || '') + '1' }
      expect(sentence.printable_form(custom_token_formatter: formatter)).to eq '1Gallia1 1est1 1omnis1 1divisa1 1in1 1partes1 1tres1, 1quarum1 1unam1 1incolunt1 1Belgae1, 1aliam1 1Aquitani1, 1tertiam1 1qui1 1ipsorum1 1lingua1 1Celtae1, 1nostra1 1Galli1 1appellantur1.  '
    end
  end

  describe 'syntax graphs' do
    let(:syntax_graph) { sentence.syntax_graph }
    let(:syntax_graphs) { sentence.syntax_graphs }

    it 'generates a single syntax graph with a root' do
      expect(syntax_graph).to be_a(Hash)
      expect(syntax_graph[:id]).to be_nil
      expect(syntax_graph[:children]).to be_a(Array)
      expect(syntax_graph[:children].first[:id]).to eq(680721) # 'est' is the root
    end

    it 'generates a list of syntax graphs' do
      expect(syntax_graphs).to be_a(Array)
      expect(syntax_graphs.first[:id]).to eq(680721)
    end
  end

  describe 'annotation metadata' do
    let(:treebank_with_metadata) { PROIEL::Treebank.new.load_from_xml(test_file('dummy-proiel-xml-2.1.xml')) }
    let(:annotated_sentence) { treebank_with_metadata.sources.first.divs.first.sentences.first }

    it 'provides access to annotator and reviewer info' do
      expect(annotated_sentence.annotated_by).to eq('john')
      expect(annotated_sentence.reviewed_by).to eq('mary')
      expect(annotated_sentence.annotated_at).to eq(DateTime.xmlschema("2016-06-04T16:35:30+01:00"))
      expect(annotated_sentence.reviewed_at).to eq(DateTime.xmlschema("2016-06-04T16:35:30+01:00"))
    end
  end
end