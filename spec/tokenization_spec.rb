#--
# Copyright (c) 2015-2016 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
require 'spec_helper'

describe PROIEL::Tokenization do
  before do
    PROIEL::Tokenization.load_patterns(File.join(File.dirname(__FILE__), 'tokenization_spec.json'))
  end

  it 'defines any non-empty string as splitable' do
    expect(PROIEL::Tokenization.is_splitable?("ab urbe")).to eql(true)
    expect(PROIEL::Tokenization.is_splitable?("urbeque")).to eql(true)
    expect(PROIEL::Tokenization.is_splitable?("a")).to eql(false)
    expect(PROIEL::Tokenization.is_splitable?("")).to eql(false)
  end

  it 'splits forms using language-specific patterns' do
    expect(PROIEL::Tokenization.split_form("lat", "ab urbe condita")).to eql(["ab", " ", "urbe", " ", "condita"])
    expect(PROIEL::Tokenization.split_form("lat", "ab urbe")).to eql(["ab", " ", "urbe"])
    expect(PROIEL::Tokenization.split_form("lat", "urbeque")).to eql(["urbe", "", "que"])
    expect(PROIEL::Tokenization.split_form("lat", "urbe")).to eql(["u", "", "r", "", "b", "", "e"])
    expect(PROIEL::Tokenization.split_form("lat", "a")).to eql(["a"])
    expect(PROIEL::Tokenization.split_form("lat", "")).to eql([""])
  end

  it 'splits forms with multiline content' do
    expect(PROIEL::Tokenization.split_form("lat", "ab urbe\ncondita")).to eql(["ab", " ", "urbe", "\n", "condita"])
  end

  it 'splits forms without using language-specific patterns' do
    expect(PROIEL::Tokenization.split_form("nolanguage", "ab urbe")).to eql(["ab", " ", "urbe"])
    expect(PROIEL::Tokenization.split_form("nolanguage", "urbeque")).to eql(["u", "", "r", "", "b", "", "e", "", "q", "", "u", "", "e"])
    expect(PROIEL::Tokenization.split_form("nolanguage", "a")).to eql(["a"])
    expect(PROIEL::Tokenization.split_form("nolanguage", "")).to eql([""])
  end

  it "splits a sequence with words in Latin script into words" do
    expect(PROIEL::Tokenization.split_form('lat', 'foobar is not barfoo, but  bar is foo!')).to eq ["foobar", " ", "is", " ", "not", " ", "barfoo", ", ", "but", "  ", "bar", " ", "is", " ", "foo", "!"]
  end

  it "splits a sequence with words in non-Latin script into words" do
    expect(PROIEL::Tokenization.split_form('grc', 'παρ’ ἀλλήλων, τὸ')).to eq ["παρ", "’ ", "ἀλλήλων", ", ", "τὸ"]
  end

  it "splits a single word in Latin script by character when no language-specific rule matches" do
    expect(PROIEL::Tokenization.split_form('XXX', 'foobar')).to eq ["f", "", "o", "", "o", "", "b", "", "a", "", "r"]
  end

  it "splits a single word in non-Latin script by character when no language-specific rule matches" do
    expect(PROIEL::Tokenization.split_form('XXX', 'μέχρι')).to eq ["μ", "", "έ", "", "χ", "", "ρ", "", "ι"]
  end
end
