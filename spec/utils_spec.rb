require 'spec_helper'

describe PROIEL::Utilities do
  describe '#xmlschema_datetime?' do
    it 'returns true for valid XML Schema datetimes' do
      expect(PROIEL::Utilities.xmlschema_datetime?('2015-07-19T00:32:45+02:00')).to be true
      expect(PROIEL::Utilities.xmlschema_datetime?('2015-07-19T00:32:45Z')).to be true
    end

    it 'returns false for invalid XML Schema datetimes' do
      expect(PROIEL::Utilities.xmlschema_datetime?('invalid')).to be false
    end
  end
end
