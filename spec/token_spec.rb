#--
# Copyright (c) 2015-2017 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
require 'spec_helper'

describe PROIEL::Token do
  let(:treebank) { PROIEL::Treebank.new.load_from_xml(test_file('dummy-proiel-xml-2.0.xml')) }
  let(:source) { treebank.sources.first }
  let(:div) { source.divs.first }
  let(:sentence) { div.sentences.first }
  let(:token) { sentence.tokens.first }

  describe '#inspect' do
    it 'returns a string representation' do
      t = PROIEL::Token.new(nil, 123, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil)
      expect(t.inspect).to eq('#<PROIEL::Token @id=123>')
    end
  end

  describe 'attributes' do
    subject { token }

    it 'provides basic attributes' do
      expect(subject.id).to eq(680720)
      expect(subject.form).to eq('Gallia')
      expect(subject.presentation_after).to eq(' ')
      expect(subject.presentation_before).to be_nil
    end

    it 'provides access to parent objects' do
      expect(subject.sentence).to eq(sentence)
      expect(subject.div).to eq(div)
      expect(subject.source).to eq(source)
      expect(subject.treebank).to eq(treebank)
    end

    it 'provides access to language' do
      expect(subject.language).to eq('lat')
    end
  end

  describe '#citation' do
    it 'generates a complete citation' do
      expect(token.citation).to eq('Caes. Gal. 1.1.1')
    end
  end

  describe '#printable_form' do
    it 'generates a printable form' do
      expect(token.printable_form).to eq('Gallia ')
    end

    it 'generates a printable form with a custom formatter' do
      formatter = lambda { |t| '1' + t.form + '1' }
      expect(token.printable_form(custom_token_formatter: formatter)).to eq('1Gallia1 ')
    end
  end

  describe 'part of speech' do
    context 'with an empty token' do
      let(:conjunction_token) { sentence.tokens.to_a[21] } # id 733299
      let(:verb_token) { sentence.tokens.to_a[22] } # id 733300

      it 'handles conjunctions' do
        expect(conjunction_token.id).to eq(733299)
        expect(conjunction_token.empty_token_sort).to eq('C')
        expect(conjunction_token.pos).to be_nil
        expect(conjunction_token.pos_with_nulls).to eq('C-')
      end

      it 'handles verbs' do
        expect(verb_token.id).to eq(733300)
        expect(verb_token.empty_token_sort).to eq('V')
        expect(verb_token.pos).to be_nil
        expect(verb_token.pos_with_nulls).to eq('V-')
      end
    end

    context 'with a regular token' do
      let(:t) { PROIEL::Token.new(nil, 1, nil, nil, nil, 'Pk', nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil) }

      it 'returns POS as string and hash' do
        expect(t.pos).to eq('Pk')
        expect(t.part_of_speech).to eq('Pk')
        expect(t.part_of_speech_hash[:major]).to eq('P')
        expect(t.part_of_speech_hash[:minor]).to eq('k')
      end
    end
  end

  describe 'morphology' do
    let(:t) { PROIEL::Token.new(nil, 1, nil, nil, nil, nil, '3spia----i', nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil) }

    it 'returns morphology as string and hash' do
      expect(t.morphology).to eq('3spia----i')
      expect(t.morphology_hash[:person]).to eq('3')
      expect(t.morphology_hash[:number]).to eq('s')
      expect(t.morphology_hash[:voice]).to eq('a')
    end
  end

  describe 'token status' do
    let(:empty_token) { PROIEL::Token.new(nil, 1, nil, nil, nil, nil, nil, nil, 'C-', nil, nil, nil, nil, nil, nil, nil, [], nil) }
    let(:content_token) { PROIEL::Token.new(nil, 1, nil, 'form', nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil) }

    it 'distinguishes empty tokens and tokens with content' do
      expect(empty_token).to be_is_empty
      expect(empty_token).not_to be_has_content

      expect(content_token).not_to be_is_empty
      expect(content_token).to be_has_content
    end
  end

  describe 'dependency graph' do
    let(:root_token) { PROIEL::Token.new(nil, 1, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil) }
    let(:headed_token) { PROIEL::Token.new(nil, 1, 2, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil) }

    it 'distinguishes headed and root tokens' do
      expect(root_token).to be_is_root
      expect(headed_token).not_to be_is_root
    end

    it 'returns the head of a token' do
      token_gallia = sentence.tokens.to_a[0] # id 680720
      token_est = sentence.tokens.to_a[1]    # id 680721
      token_divisa = sentence.tokens.to_a[3] # id 680723

      expect(token_gallia.head.id).to eq(680721)
      expect(token_est.head).to be_nil
      expect(token_divisa.head.id).to eq(680721)
    end

    it 'returns the dependents of a token' do
      token_est = sentence.tokens.to_a[1] # id 680721
      expect(token_est.dependents.map(&:id).sort).to eq([680720, 680723])
    end

    it 'returns the ancestors of a token' do
      token_quarum = sentence.tokens.to_a[7] # id 680727
      expect(token_quarum.ancestors.map(&:id)).to eq([680728, 680729, 733299, 680725, 680724, 680723, 680721])
    end

    it 'returns the descendents of a token' do
      token_est = sentence.tokens.to_a[1] # id 680721
      expect(token_est.descendents.map(&:id).sort).to eq([680720, 680722, 680723, 680724, 680725, 680726, 680727, 680728, 680729, 680730, 680731, 680732, 680733, 680734, 680735, 680736, 680737, 680738, 680739, 680740, 733299, 733300, 733301, 733302, 733303])
    end
  end

  describe 'common ancestors' do
    #   x.head # => w
    #   w.head # => z
    #   y.head # => z
    #   z.head # => u
    #
    #   [u [z [y] [w [x]]]]
    let(:manual_treebank) { PROIEL::Treebank.new }
    let(:manual_sentence) do
      s = nil
      src = PROIEL::Source.new(manual_treebank, 'foo', nil, 'lat', nil, {}, nil) do |src|
        [PROIEL::Div.new(src, 0, nil, nil, nil, nil) do |div|
          [PROIEL::Sentence.new(div, 1, :unannotated, nil, nil, nil, nil, nil, nil, nil) do |sent|
            s = sent
            u = PROIEL::Token.new(sent, 5, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil)
            z = PROIEL::Token.new(sent, 3, u.id, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil)
            y = PROIEL::Token.new(sent, 2, z.id, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil)
            w = PROIEL::Token.new(sent, 4, z.id, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil)
            x = PROIEL::Token.new(sent, 1, w.id, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil)
            [x, y, z, w, u]
          end]
        end]
      end
      manual_treebank.sources << src
      manual_treebank.send(:index_source_objects!, src)
      s
    end

    let(:x) { manual_sentence.tokens.find { |t| t.id == 1 } }
    let(:y) { manual_sentence.tokens.find { |t| t.id == 2 } }
    let(:z) { manual_sentence.tokens.find { |t| t.id == 3 } }
    let(:w) { manual_sentence.tokens.find { |t| t.id == 4 } }
    let(:u) { manual_sentence.tokens.find { |t| t.id == 5 } }

    it 'finds common ancestors (exclusive)' do
      expect(x.common_ancestors(y, inclusive: false)).to eq([z, u])
      expect(x.common_ancestors(w, inclusive: false)).to eq([z, u])
      expect(x.common_ancestors(x, inclusive: false)).to eq([w, z, u])
    end

    it 'finds common ancestors (inclusive)' do
      expect(x.common_ancestors(y, inclusive: true)).to eq([z, u])
      expect(x.common_ancestors(w, inclusive: true)).to eq([w, z, u])
      expect(x.common_ancestors(x, inclusive: true)).to eq([x, w, z, u])
    end

    it 'finds first common ancestor' do
      expect(x.first_common_ancestor(y, inclusive: false)).to eq(z)
      expect(x.first_common_ancestor(w, inclusive: true)).to eq(w)
    end
  end
end