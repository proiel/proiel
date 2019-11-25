#--
# Copyright (c) 2019 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
describe PROIEL::Language do
  it 'detects supported languages' do
    expect(PROIEL::Language.language_supported?(:lat)).to eq true
    expect(PROIEL::Language.language_supported?('lat')).to eq true
    expect(PROIEL::Language.language_supported?(:invalid_language_tag)).to eq false
    expect(PROIEL::Language.language_supported?('invalid_language_tag')).to eq false
  end

  it 'gets the display name' do
    expect(PROIEL::Language.get_display_name(:lat)).to eq 'Latin'
    expect(PROIEL::Language.get_display_name('lat')).to eq 'Latin'
  end

  it 'raises an argument error for invalid language tags' do
    expect { PROIEL::Language.get_display_name(:invalid_language_tag) }.to raise_error(ArgumentError)
  end

  it 'raises an argument error for bad arguments' do
    expect { PROIEL::Language.get_display_name(nil) }.to raise_error(ArgumentError)
    expect { PROIEL::Language.get_display_name(3) }.to raise_error(ArgumentError)
  end

  it 'returns all supported language tags' do
    expect(PROIEL::Language.supported_language_tags).to include(:lat)
    expect(PROIEL::Language.supported_language_tags).to include(:orv)
    expect(PROIEL::Language.supported_language_tags).to include(:grc)
  end
end
