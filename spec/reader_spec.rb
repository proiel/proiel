#--
# Copyright (c) 2015 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
require 'spec_helper'

describe PROIEL::PROIELXML::Reader do
  it 'can load PROIEL XML with multiple sources' do
    f = PROIEL::PROIELXML::Reader.parse_io(open_test_file('multiple-sources.xml'))

    expect(f.proiel.sources.length).to eql(2)
    expect(f.proiel.sources[0].id).to eql('caes-gal')
    expect(f.proiel.sources[1].id).to eql('cic-att')
  end
end
