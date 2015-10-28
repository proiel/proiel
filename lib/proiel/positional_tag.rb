#--
# Copyright (c) 2015 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
module PROIEL
  # Represents a positional tag, which consists of one or more fields each with
  # its own value. The default implementation is of a positional tag with no
  # fields. The class should be subclassed and the `fields` method overridden
  # to implement a non-empty positional tag.
  #
  # @abstract Subclass and override {#fields} to implement a custom positional tag class.
  class PositionalTag
    include Comparable

    # Creates a new positional tag.
    #
    # @param value [String, Hash, PositionalTag] initial value
    #
    def initialize(value = nil)
      @fields = Hash.new

      case value
      when NilClass
      when String
        set_value!(fields.zip(value.split('')).to_h)
      when Hash
        set_value!(value)
      when PositionalTag
        set_value!(value.to_h)
      else
        raise ArgumentError, 'expected nil, Hash, String or PositionalTag'
      end
    end

    # Returns an integer, -1, 0 or 1, suitable for sorting the tag.
    #
    # @return [Integer]
    #
    def <=>(o)
      to_s <=> o.to_s
    end

    # Returns the positional tag as a string.
    #
    # @return [String]
    #
    def to_s
      # Iterate fields to ensure conversion of fields without a value to
      # UNSET_FIELD.
      fields.map { |field| self[field] }.join
    end

    # Checks if the tag is unitialized. The tag is uninitialized if no field
    # has a value.
    #
    # @return [true, false]
    #
    def empty?
      @fields.empty?
    end

    # Returns a hash representation of the tag. The keys are the names of each
    # field as symbols, the values are the values of each field.
    #
    # @return [Hash<Symbol, String>]
    #
    def to_h
      @fields
    end

    # Returns the value of a field. An field without a value is returned
    # as `-`.
    #
    # @param field [String, Symbol] name of field
    #
    # @return [String]
    #
    def [](field)
      field = field.to_sym

      raise ArgumentError, "invalid field #{field}" unless fields.include?(field)

      @fields[field] || UNSET_FIELD
    end

    # Assigns a value to a field. Removing any value from a field can be done
    # by assigning `nil` or `-`.
    #
    # @param field [String, Symbol] name of field
    # @param value [String, nil]
    #
    # @return [String]
    #
    def []=(field, value)
      field = field.to_sym

      raise ArgumentError, "invalid field #{field}" unless fields.include?(field)

      if value == UNSET_FIELD or value.nil?
        @fields.delete(field)
      else
        @fields.store(field, value)
      end

      value
    end

    # Returns the field names. This method should be overridden by
    # implementations. The names should be returned as an array of symbols.
    #
    # @return [Array<Symbol>]
    #
    def fields
      []
    end

    private

    # The string representation of a field without a value.
    UNSET_FIELD = '-'.freeze

    def set_value!(o)
      o.each { |k, v| self[k] = v }
    end
  end
end
