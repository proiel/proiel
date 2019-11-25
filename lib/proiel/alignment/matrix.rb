module PROIEL
  module Alignment
    class Matrix
      def initialize(matrix)
        @matrix = matrix
      end

      def save!(filename)
        File.open(filename, 'w') do |f|
          f.write @matrix.to_json
        end
      end

      def self.load(filename)
        obj = nil

        File.open(filename) do |f|
          matrix = JSON.parse(f.read, symbolize_names: true)

          obj = Matrix.new(matrix)
        end

        obj
      end

      def self.compute(alignment, source, blacklist = [], log_directory = nil)
        matrix = PROIEL::Alignment::Builder.compute_matrix(alignment, source, blacklist, log_directory)

        Matrix.new(matrix)
      end
    end
  end
end
