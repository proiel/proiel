#--
# Copyright (c) 2015 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
require 'spec_helper'

describe PROIEL::Citations do
  it 'computes prefixes based on chunks not strings' do
    expect(PROIEL::Citations.citation_strip_prefix('Matt 5.16', 'Matt 5.27')).to eql('27')
    expect(PROIEL::Citations.citation_strip_prefix('Matt 5.26', 'Matt 5.27')).to eql('27')
  end

  it 'computes the longest common prefix' do
    expect(PROIEL::Citations.citation_strip_prefix('Matt 4.13', 'Matt 5.27')).to eql('5.27')
    expect(PROIEL::Citations.citation_strip_prefix('Matt 6.13', 'Matt 5.27')).to eql('5.27')
    expect(PROIEL::Citations.citation_strip_prefix('Mark 1.13', 'Matt 5.27')).to eql('Matt 5.27')
    expect(PROIEL::Citations.citation_strip_prefix('Mark 5.27', 'Matt 5.27')).to eql('Matt 5.27')
  end

  it 'computes prefixes even when citations are unbalanced' do
    expect(PROIEL::Citations.citation_strip_prefix('Matt 5.16', 'Matt 5')).to eql('')
    expect(PROIEL::Citations.citation_strip_prefix('Matt 5.16', '')).to eql('')
    expect(PROIEL::Citations.citation_strip_prefix('Matt 5',    'Matt 5.16')).to eql('.16')
    expect(PROIEL::Citations.citation_strip_prefix('',          'Matt 5.16')).to eql('Matt 5.16')
  end

  it 'makes ranges based on chunks not strings' do
    expect(PROIEL::Citations.citation_make_range('Matt 5.16', 'Matt 5.27')).to eql('Matt 5.16–27')
    expect(PROIEL::Citations.citation_make_range('Matt 5.26', 'Matt 5.27')).to eql('Matt 5.26–27')
  end

  it 'makes ranges based on the longest common prefix' do
    expect(PROIEL::Citations.citation_make_range('Matt 4.13', 'Matt 5.27')).to eql('Matt 4.13–5.27')
    expect(PROIEL::Citations.citation_make_range('Matt 6.13', 'Matt 5.27')).to eql('Matt 6.13–5.27')
    expect(PROIEL::Citations.citation_make_range('Mark 1.13', 'Matt 5.27')).to eql('Mark 1.13–Matt 5.27')
    expect(PROIEL::Citations.citation_make_range('Mark 5.27', 'Matt 5.27')).to eql('Mark 5.27–Matt 5.27')
  end

  it 'makes ranges even when citations are unbalanced' do
    expect(PROIEL::Citations.citation_make_range('Matt 5.16', 'Matt 5')).to eql('Matt 5.16')
    expect(PROIEL::Citations.citation_make_range('Matt 5.16', '')).to eql('Matt 5.16')
    expect(PROIEL::Citations.citation_make_range('Matt 5',    'Matt 5.16')).to eql('Matt 5–.16')
    expect(PROIEL::Citations.citation_make_range('',          'Matt 5.16')).to eql('Matt 5.16')
  end
end
