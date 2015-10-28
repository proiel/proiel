#--
# Copyright (c) 2015 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
module PROIEL
  module Citations
    # Returns a citation range that spans `cit1` to `cit2`.
    #
    # The regular expression `dividers` is used to chunk the strings, and then
    # the longest common prefix of chunks is removed from `cit2`. `dividers`
    # should chosen so that the chunks match logical components of a citation,
    # e.g. book titles, chapter numbers and section identifiers.
    #
    # @param cit1 [String] first citation in range
    # @param cit2 [String] second citation in range
    # @param dividers [Regexp] dividing elements between components of citation
    #
    # @return [String]
    #
    # @example
    #   citation_make_range('Matt 5.16', 'Matt 5.27') # => "Matt 5.16–27"
    #   citation_make_range('Matt 4.13', 'Matt 5.27') # => "Matt 4.13–5.27"
    #
    def self.citation_make_range(cit1, cit2, dividers: /([\s\.]+)/)
      raise ArgumentError unless cit1.is_a?(String) or cit1.nil?
      raise ArgumentError unless cit2.is_a?(String) or cit1.nil?

      # Remove any nil and empty-string citation, and reduce a range that starts
      # and ends with the same citation to a single citation.
      c = [cit1, cit2].reject { |c| c.nil? || c.empty? }.uniq

      case c.length
      when 0
        nil
      when 1
        c.first
      else
        s = citation_strip_prefix(cit1, cit2, dividers: dividers)
        [cit1, s].reject(&:empty?).join("\u{2013}")
      end
    end

    # Returns `cit2` without the longest prefix that `cit1` and `cit2` have in
    # common.
    #
    # The longest common prefix is not computed from the raw strings `cit1` and
    # `cit2` but from string chunks. The regular expression `dividers` is used
    # to chunk the strings, and then the longest prefix of chunks is removed.
    #
    # `dividers` should chosen so that the chunks match logical componets of a
    # citation, e.g. book titles, chapter numbers and section identifiers.
    #
    # @param cit1 [String] first citation in range
    # @param cit2 [String] second citation in range
    # @param dividers [Regexp] dividing elements between components of citation
    #
    # @return [String]
    #
    # @example
    #   citation_strip_prefix('Matt 5.16', 'Matt 5.27') # => "27"
    #   citation_strip_prefix('Matt 5.26', 'Matt 5.27') # => "27"
    #   citation_strip_prefix('Matt 4.13', 'Matt 5.27') # => "5.27"
    #
    def self.citation_strip_prefix(cit1, cit2, dividers: /([\s\.]+)/u)
      raise ArgumentError unless cit1.is_a?(String)
      raise ArgumentError unless cit2.is_a?(String)

      x, y = cit1.split(dividers), cit2.split(dividers)

      # Interleave x and y but compensate for zip's behaviour when
      # y.length < x.length
      zipped = x.length >= y.length ? x.zip(y) : y.zip(x).map(&:reverse)

      zipped.inject('') do |d, (a, b)|
        if not d.empty? or a != b
          d + (b || '')
        else
          ''
        end
      end
    end
  end
end
