#--
# Copyright (c) 2015-2017 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
require 'spec_helper'

describe PROIEL::Token do
  it 'has an inspect method' do
    t = PROIEL::Token.new(nil, 123, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                          nil, nil, nil, nil, nil, [], nil)
    expect(t.inspect).to eql('#<PROIEL::Token @id=123>')
  end

  it 'provides id, form, presentation_before, presentation_after access' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first
    sentence = div.sentences.first
    token = sentence.tokens.first

    expect(token.id).to eql(680720)
    expect(token.form).to eql('Gallia')
    expect(token.presentation_after).to eql(' ')
    expect(token.presentation_before).to eql(nil)
  end

  it 'provides access to parent objects' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first
    sentence = div.sentences.first
    token = sentence.tokens.first

    expect(token.sentence).to eql(sentence)
    expect(token.div).to eql(div)
    expect(token.source).to eql(source)
    expect(token.treebank).to eql(tb)
  end

  it 'generates a complete citation' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first
    sentence = div.sentences.first
    token = sentence.tokens.first

    expect(token.citation).to eql('Caes. Gal. 1.1.1')
  end

  it 'generates a printable form' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first
    sentence = div.sentences.first
    token = sentence.tokens.first

    expect(token.printable_form).to eql('Gallia ')

    formatter = lambda { |token|
      '1' + token.form + '1'
    }

    expect(token.printable_form(custom_token_formatter: formatter)).to eql('1Gallia1 ')
  end

  it 'provides access to the language' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first
    sentence = div.sentences.first
    token = sentence.tokens.first

    expect(token.language).to eql('lat')
  end

  it 'can generate a POS for empty tokens' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first
    sentence = div.sentences.first

    token = sentence.tokens.to_a[21]

    expect(token.id).to eql(733299)
    expect(token.empty_token_sort).to eql('C')
    expect(token.pos).to eql(nil)
    expect(token.pos_with_nulls).to eql('C-')
    expect(token.part_of_speech).to eql(nil)
    expect(token.part_of_speech_with_nulls).to eql('C-')

    token = sentence.tokens.to_a[22]

    expect(token.id).to eql(733300)
    expect(token.empty_token_sort).to eql('V')
    expect(token.pos).to eql(nil)
    expect(token.pos_with_nulls).to eql('V-')
    expect(token.part_of_speech).to eql(nil)
    expect(token.part_of_speech_with_nulls).to eql('V-')
  end

  it 'returns POS as a string and as a hash' do
    t = PROIEL::Token.new(nil, 1, nil, nil, nil, 'Pk', nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil)

    expect(t.pos).to eql('Pk')
    expect(t.part_of_speech).to eql('Pk')
    expect(t.part_of_speech_hash[:major]).to eql('P')
    expect(t.part_of_speech_hash[:minor]).to eql('k')
  end

  it 'returns morphology as a string and as a hash' do
    t = PROIEL::Token.new(nil, 1, nil, nil, nil, nil, '3spia----i', nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil)

    expect(t.morphology).to eql('3spia----i')
    expect(t.morphology_hash[:person]).to eql('3')
    expect(t.morphology_hash[:number]).to eql('s')
    expect(t.morphology_hash[:voice]).to eql('a')
  end

  it 'distinguishes empty tokens and tokens with content' do
    s = PROIEL::Token.new(nil, 1, nil, nil, nil, nil, nil, nil, 'C-', nil, nil, nil, nil, nil, nil, nil, [], nil)
    t = PROIEL::Token.new(nil, 1, nil, 'form', nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil)

    expect(s.is_empty?).to eql(true)
    expect(s.has_content?).to eql(false)

    expect(t.is_empty?).to eql(false)
    expect(t.has_content?).to eql(true)
  end

  it 'distinguishes headed and root tokens' do
    s = PROIEL::Token.new(nil, 1, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil)
    t = PROIEL::Token.new(nil, 1, 2, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil)

    expect(s.is_root?).to eql(true)
    expect(t.is_root?).to eql(false)
  end

  it 'returns the head of a token' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first
    sentence = div.sentences.first

    token_gallia = sentence.tokens.to_a[0]
    token_est = sentence.tokens.to_a[1]
    token_divisa = sentence.tokens.to_a[3]

    expect(token_gallia.id).to eql(680720)
    expect(token_gallia.head.id).to eql(680721)
    expect(token_gallia.head_id).to eql(680721)

    expect(token_est.id).to eql(680721)
    expect(token_est.head).to eql(nil)
    expect(token_est.head_id).to eql(nil)

    expect(token_divisa.id).to eql(680723)
    expect(token_divisa.head.id).to eql(680721)
    expect(token_divisa.head_id).to eql(680721)
  end

  it 'returns the dependents of a token' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first
    sentence = div.sentences.first

    token_gallia = sentence.tokens.to_a[0]
    token_est = sentence.tokens.to_a[1]
    token_divisa = sentence.tokens.to_a[3]

    expect(token_gallia.id).to eql(680720)
    expect(token_gallia.dependents.map(&:id).sort).to eql([680722])

    expect(token_est.id).to eql(680721)
    expect(token_est.dependents.map(&:id).sort).to eql([680720, 680723])

    expect(token_divisa.id).to eql(680723)
    expect(token_divisa.dependents.map(&:id).sort).to eql([680724])
  end

  it 'returns the ancestors of a token' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first
    sentence = div.sentences.first

    token_gallia = sentence.tokens.to_a[0]
    token_est = sentence.tokens.to_a[1]
    token_divisa = sentence.tokens.to_a[3]
    token_quarum = sentence.tokens.to_a[7]

    expect(token_gallia.id).to eql(680720)
    expect(token_gallia.ancestors.map(&:id)).to eql([680721])

    expect(token_est.id).to eql(680721)
    expect(token_est.ancestors.map(&:id)).to eql([])

    expect(token_divisa.id).to eql(680723)
    expect(token_divisa.ancestors.map(&:id)).to eql([680721])

    expect(token_quarum.id).to eql(680727)
    expect(token_quarum.ancestors.map(&:id)).to eql([680728, 680729, 733299, 680725, 680724, 680723, 680721])
  end

  it 'returns the descendents of a token' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))

    source = tb.sources.first
    div = source.divs.first
    sentence = div.sentences.first

    token_gallia = sentence.tokens.to_a[0]
    token_est = sentence.tokens.to_a[1]
    token_tres = sentence.tokens.to_a[6]
    token_quarum = sentence.tokens.to_a[7]

    expect(token_gallia.id).to eql(680720)
    expect(token_gallia.descendents.map(&:id).sort).to eql([680722])

    expect(token_est.id).to eql(680721)
    expect(token_est.descendents.map(&:id).sort).to eql([680720, 680722, 680723, 680724, 680725, 680726, 680727, 680728, 680729, 680730, 680731, 680732, 680733, 680734, 680735, 680736, 680737, 680738, 680739, 680740, 733299, 733300, 733301, 733302, 733303])

    expect(token_tres.id).to eql(680726)
    expect(token_tres.ancestors.map(&:id)).to eql([680725, 680724, 680723, 680721])

    expect(token_quarum.id).to eql(680727)
    expect(token_quarum.descendents.map(&:id).sort).to eql([])
  end

  it 'returns the common ancestors of two tokens' do
    # Test the documented scenario:
    #
    #   x.head # => w
    #   w.head # => z
    #   y.head # => z
    #   z.head # => u
    #
    # i.e.
    #
    #   [u [z [y] [w [x]]]]
    #
    #
    x, y, z, w, u = nil, nil, nil, nil, nil

    treebank = PROIEL::Treebank.new

    source = PROIEL::Source.new(treebank, 'foobar', DateTime.now.to_s, 'lat', nil, nil) do |source|
      [PROIEL::Div.new(source, 0, nil, nil, nil, nil) do |div|
        [PROIEL::Sentence.new(div, 1, :unannotated, nil, nil, nil, nil, nil, nil, nil) do |sentence|
          u = PROIEL::Token.new(sentence, 5, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil)
          z = PROIEL::Token.new(sentence, 3, u.id, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil)
          y = PROIEL::Token.new(sentence, 2, z.id, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil)
          w = PROIEL::Token.new(sentence, 4, z.id, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil)
          x = PROIEL::Token.new(sentence, 1, w.id, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil)

          [x, y, z, w, u]
        end]
      end]
    end

    treebank.sources << source
    treebank.send(:index_objects!, source)

    expect(x.common_ancestors(y, inclusive: false)).to eql([z, u])
    expect(x.common_ancestors(w, inclusive: false)).to eql([z, u])
    expect(x.common_ancestors(x, inclusive: false)).to eql([w, z, u])

    expect(x.common_ancestors(y, inclusive: true)).to eql([z, u])
    expect(x.common_ancestors(w, inclusive: true)).to eql([w, z, u])
    expect(x.common_ancestors(x, inclusive: true)).to eql([x, w, z, u])

    expect(x.first_common_ancestor(y, inclusive: false)).to eql(z)
    expect(x.first_common_ancestor(w, inclusive: false)).to eql(z)
    expect(x.first_common_ancestor(x, inclusive: false)).to eql(w)

    expect(x.first_common_ancestor(y, inclusive: true)).to eql(z)
    expect(x.first_common_ancestor(w, inclusive: true)).to eql(w)
    expect(x.first_common_ancestor(x, inclusive: true)).to eql(x)
  end
end
