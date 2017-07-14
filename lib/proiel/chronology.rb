#--
# Copyright (c) 2016-2017 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++

# Methods for parsing chronological descriptions.  Extra care is taken to get
# the interpretation of centuries and ranges involving the transition between 1
# BC and AD 1 correct.
module PROIEL::Chronology
  # Computes the chronological midpoint of a chronological description.
  #
  # @param s [String] chronological description
  #
  # @return [Integer]
  #
  # @example
  #   midpoint('1000')         # => 1000
  #   midpoint('1000 BC')      # => -1000
  #   midpoint('1000-1020')    # => 1010
  def self.midpoint(s)
    i = parse(s)

    if i.is_a?(Array)
      # Handle missing Julian year 0 by shifting years after 1 BC down by 1 and then shifting the midpoint back
      # up again unless negative
      if i.first < 0 and i.last > 0
        y = (i.first + i.last - 1)/2.0
        if y < 0
          y.floor
        else
          (y + 1).floor
        end
      else
        ((i.first + i.last)/2.0).floor # a non-integer midpoint is within the year of the integer part
      end
    elsif i.is_a?(Integer)
      i
    else
      raise ArgumentError, 'integer or array expected'
    end
  end

  # Parses a chronological description. The syntax of chronological
  # descriptions is explained in the [PROIEL XML
  # documentation](http://proiel.github.io/handbook/developer/proielxml.html#chronological-data).
  #
  # @param s [String] chronological description
  #
  # @return [Integer, Array<Integer,Integer>]
  #
  # @example
  #   parse('1000')         # => 1000
  #   parse('1000 BC')      # => -1000
  #   parse('1000-1020')    # => [1000,1020]
  #   parse('1000 BC-1020') # => [-1000,1020]
  def self.parse(s)
    case s
    when /^\s*(?:c\.\s+)?(\d+)(\s+BC)?\s*$/
      i = $1.to_i
      multiplier = $2 ? -1 : 1
      (i * multiplier).to_i.tap do |i|
        # There is no year zero in the Julian calendar
        raise ArgumentError, 'invalid year' if i.zero?
      end
    when /^\s*(1st|2nd|3rd|\d+th)\s+c\.\s*$/
      a = $1.to_i * 100
      [a - 99, a]
    when /^\s*(1st|2nd|3rd|\d+th)\s+c\.\s+BC\s*$/
      a = -$1.to_i * 100
      [a, a + 99]
    when /^\s*(?:c\.\s+)?\d+(\s+BC)?\s*-\s*(c\.\s+)?\d+(\s+BC)?\s*$/
      s.split('-').map { |i| self.parse(i) }.tap do |from, to|
        raise ArgumentError, 'invalid range' unless from < to
      end
    else
      raise ArgumentError, 'unexpected format'
    end
  end
end
