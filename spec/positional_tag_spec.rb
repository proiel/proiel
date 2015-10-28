#--
# Copyright (c) 2015 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
require 'spec_helper'

class MyPositionalTag < PROIEL::PositionalTag
  def fields
    [:a, :b, :c, :d]
  end
end

describe PROIEL::PositionalTag do
  it 'can be instantiated without a value' do
    o = MyPositionalTag.new
    expect(o).to be_kind_of(PROIEL::PositionalTag)
    expect(o.to_s).to eql('----')
  end

  it 'can be instantiated with a string value' do
    o = MyPositionalTag.new('D---')
    expect(o).to be_kind_of(PROIEL::PositionalTag)
    expect(o.to_s).to eql('D---')
  end

  it 'can be instantiated with a hash' do
    o = MyPositionalTag.new(a: 'D')

    expect(o).to be_kind_of(PROIEL::PositionalTag)
    expect(o.to_s).to eql('D---')
  end

  it 'can be instantiated with another object' do
    x = MyPositionalTag.new('D---')
    o = MyPositionalTag.new(x)

    expect(o).to be_kind_of(PROIEL::PositionalTag)
    expect(o.to_s).to eql('D---')
  end

  it 'can be tested for (un)equality' do
    x = MyPositionalTag.new('D-a-')
    y = MyPositionalTag.new('D-a-')
    z = MyPositionalTag.new('D--x')

    expect(x == y).to eql(true)
    expect(x == z).to eql(false)
    expect(y == z).to eql(false)

    expect(x != y).to eql(false)
    expect(x != z).to eql(true)
    expect(y != z).to eql(true)
  end

  it 'can be compared' do
    x = MyPositionalTag.new('D-a-')
    y = MyPositionalTag.new('D-a-')
    z = MyPositionalTag.new('D-b-')

    expect(x <=> x).to eql(0)
    expect(x <=> y).to eql(0)
    expect(y <=> x).to eql(0)

    expect(x <=> z).to eql(-1)
    expect(z <=> x).to eql(1)

    expect(x < y).to eql(false)
    expect(x < z).to eql(true)
    expect(y < z).to eql(true)
  end

  it 'can have its values manipulated' do
    x = MyPositionalTag.new('D-a-')

    x[:a] = 'E'
    expect(x.to_s).to eql('E-a-')
  end

  it 'can recognizes a default/nil value' do
    x = MyPositionalTag.new('D-a-')

    x[:a] = '-'
    expect(x.to_s).to eql('--a-')

    x[:a] = nil
    expect(x.to_s).to eql('--a-')
  end

  it 'can be tested for emptiness/lack of initialization' do
    x = MyPositionalTag.new()
    expect(x.empty?).to eql(true)

    x = MyPositionalTag.new('----')
    expect(x.empty?).to eql(true)

    x = MyPositionalTag.new('D---')
    x[:a] = nil
    expect(x.empty?).to eql(true)

    x = MyPositionalTag.new('D---')
    x[:a] = '-'
    expect(x.empty?).to eql(true)

    x = MyPositionalTag.new('D---')
    expect(x.empty?).to eql(false)
  end

  it 'can be converted to a hash' do
    x = MyPositionalTag.new('D---')
    expect(x.to_h).to eql({ a: 'D' })
  end

  it 'can be accessed by field' do
    x = MyPositionalTag.new('D---')
    expect(x[:a]).to eql('D')

    x = MyPositionalTag.new('----')
    expect(x[:a]).to eql('-')
  end

  it 'has a default implementation of fields' do
    x = PROIEL::PositionalTag.new(nil)
    expect(x.fields).to eql([])
  end

  it 'raises an exception on incorrect initialization' do
    expect { MyPositionalTag.new(1) }.to raise_error(ArgumentError)
  end
end
