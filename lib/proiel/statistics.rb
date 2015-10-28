#--
# Copyright (c) 2015 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
module PROIEL
  module Statistics
    # Computes the line of best fit using the least-squares method.
    #
    # @param x [Array<Number>] x-values
    # @param y [Array<Number>] y-values
    #
    # @return [Array(Float, Float)] y-intercept and slope
    #
    # @example
    #   x = [8, 2, 11, 6, 5, 4, 12, 9, 6, 1]
    #   y = [3, 10, 3, 6, 8, 12, 1, 4, 9, 14]
    #   a, b = PROIEL::Statistics.least_squares(x, y)
    #   a # => 14.081081081081088
    #   b # => -1.1064189189189197
    #
    def self.least_squares(x, y)
      raise ArgumentError unless x.is_a?(Array)
      raise ArgumentError unless y.is_a?(Array)
      raise ArgumentError, 'array lengths differ' unless x.size == y.size

      x_mean = x.reduce(&:+).to_f / x.size
      y_mean = y.reduce(&:+).to_f / y.size
      x_sqsum = x.reduce(0.0) { |sum, n| sum + n ** 2 }
      xy_sum = x.zip(y).reduce(0.0) { |sum, (m, n)| sum + m * n }

      sxy = xy_sum - x.length * x_mean * y_mean
      sx2 = x_sqsum - x.length * (x_mean ** 2)

      beta = sxy / sx2
      alfa = y_mean - beta * x_mean

      [alfa, beta]
    end
  end
end
