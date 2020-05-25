module PROIEL
  module Utilities
    def self.xmlschema_datetime?(s)
      DateTime.xmlschema(s)

      true
    rescue ArgumentError => e
      if e.message == 'invalid date'
        false
      else
        raise e
      end
    end
  end
end
