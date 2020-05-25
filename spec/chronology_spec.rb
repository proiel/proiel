#--
# Copyright (c) 2016-2018 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
describe PROIEL::Chronology do
  it 'parses a single integer year' do
    expect(PROIEL::Chronology.parse('1040')).to eq 1040
    expect(PROIEL::Chronology.parse('300 BC')).to eq -300
  end

  it 'catches an invalid integer year' do
    expect { PROIEL::Chronology.parse('0')    }.to raise_error(ArgumentError)
    expect { PROIEL::Chronology.parse('0 BC') }.to raise_error(ArgumentError)
  end

  it 'parses an uncertain integer year' do
    expect(PROIEL::Chronology.parse('c. 1050')).to eq 1050
    expect(PROIEL::Chronology.parse('c. 100 BC')).to eq -100
  end

  it 'parses a range of integer years' do
    expect(PROIEL::Chronology.parse('1040-1045')).to eq [1040, 1045]
    expect(PROIEL::Chronology.parse('30 BC-20 BC')).to eq [-30, -20]
    expect(PROIEL::Chronology.parse('10 BC-10')).to eq [-10, 10]
  end

  it 'catches an invalid range' do
    expect { PROIEL::Chronology.parse('10-10 BC')    }.to raise_error(ArgumentError)
    expect { PROIEL::Chronology.parse('10 BC-10 BC') }.to raise_error(ArgumentError)
    expect { PROIEL::Chronology.parse('10-10')       }.to raise_error(ArgumentError)
    expect { PROIEL::Chronology.parse('20-10')       }.to raise_error(ArgumentError)
    expect { PROIEL::Chronology.parse('0-10')        }.to raise_error(ArgumentError)
  end

  it 'parses a range of uncertain integer years' do
    expect(PROIEL::Chronology.parse('c. 1050-c. 1100')).to eq [1050, 1100]
    expect(PROIEL::Chronology.parse('c. 30 BC-c. 20 BC')).to eq [-30, -20]
    expect(PROIEL::Chronology.parse('c. 10 BC-c. 10')).to eq [-10, 10]
  end

  it 'parses a century designation' do
    expect(PROIEL::Chronology.parse('13th c.')).to eq [1201, 1300]
    expect(PROIEL::Chronology.parse('1st c.')).to eq [1, 100]
    expect(PROIEL::Chronology.parse('1st c. BC')).to eq [-100, -1]
  end

  it 'identifies the midpoint for a single integer year as the year itself' do
    expect(PROIEL::Chronology.midpoint('1040')).to eq 1040
    expect(PROIEL::Chronology.midpoint('300 BC')).to eq -300
  end

  it 'identifies the midpoint for an uncertain integer year as the year itself' do
    expect(PROIEL::Chronology.midpoint('c. 1050')).to eq 1050
    expect(PROIEL::Chronology.midpoint('c. 100 BC')).to eq -100
  end

  it 'identifies the midpoint for a range of integer years' do
    expect(PROIEL::Chronology.midpoint('1040-1046')).to eq 1043
    expect(PROIEL::Chronology.midpoint('30 BC-20 BC')).to eq -25

    # The midpoint 1000.5 is still within year 1000
    expect(PROIEL::Chronology.midpoint('1000-1001')).to eq 1000

    # The midpoint -1000.5 is still within year 1001 BC
    expect(PROIEL::Chronology.midpoint('1001 BC-1000 BC')).to eq -1001

    # The relevant years are [1 BC, 1, 2] so the midpoint is 1
    expect(PROIEL::Chronology.midpoint('1 BC-2')).to eq 1

    # The relevant years are [2 BC, 1 BC, 1] so the midpoint is 1 BC
    expect(PROIEL::Chronology.midpoint('1 BC-1')).to eq -1

    # The relevant years are [1 BC, 1] so the midpoint is within year 1 BC
    expect(PROIEL::Chronology.midpoint('1 BC-1')).to eq -1

    # The relevant years are [2 BC, 1 BC, 1, 2] so the midpoint is within year 1 BC
    expect(PROIEL::Chronology.midpoint('2 BC-2')).to eq -1

    # The relevant years are [1 BC, 1, 2, 3] so the midpoint is within year 1
    expect(PROIEL::Chronology.midpoint('1 BC-3')).to eq 1
  end

  it 'identifies the midpoint for a range of uncertain integer years' do
    expect(PROIEL::Chronology.midpoint('c. 1050-c. 1100')).to eq 1075
    expect(PROIEL::Chronology.midpoint('c. 30 BC-c. 20 BC')).to eq -25

    # FIXME
    # expect(PROIEL::Chronology.midpoint('c. 10 BC-c. 10')).to eq -0.5
  end

  it 'parses a century designation' do
    expect(PROIEL::Chronology.parse('13th c.')).to eq [1201, 1300]
    expect(PROIEL::Chronology.parse('1st c.')).to eq [1, 100]
    expect(PROIEL::Chronology.parse('1st c. BC')).to eq [-100, -1]
  end

  it 'can be loaded from a PROIEL XML > 3.0 file' do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('data/proielxml-3.0-skeleton.xml'))

    o = tb.sources.first.chronology_composition
    expect(o).to eql('30 BC-20 BC')
    expect(PROIEL::Chronology.midpoint(o)).to eq -25

    o = tb.sources.first.chronology_manuscript
    expect(o).to eql('c. 1050')
    expect(PROIEL::Chronology.midpoint(o)).to eq 1050
  end
end
