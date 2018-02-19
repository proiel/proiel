module PROIEL
  module Alignment
    module Builder
      # This computes a matrix of original and translation sentences that are
      # aligned. For now, this function does not handle translation sentences that
      # are unaligned (this is tricky to handle robustly!). As the current treebank
      # collection stands this is an issue that *should* not arise so this is for
      # now a reasonable approximation.
      def self.compute_matrix(alignment, source, blacklist = [], log_directory = nil)
        matrix1 = group_backwards(alignment, source, blacklist)
        raise unless matrix1.map { |r| r[:original]    }.flatten.compact == alignment.sentences.map(&:id)

        matrix2 = group_forwards(alignment, source, blacklist)
        raise unless matrix2.map { |r| r[:translation] }.flatten.compact == source.sentences.map(&:id)

        if log_directory
          # Verify that both texts are still in the correct sequence
          File.open(File.join(log_directory, "#{source.id}1"), 'w') do |f|
            matrix1.map do |x|
              f.puts x.inspect
            end
          end

          File.open(File.join(log_directory, "#{source.id}2"), 'w') do |f|
            matrix2.map do |x|
              f.puts x.inspect
            end
          end
        end

        matrix = []
        iter1 = { i: 0, m: matrix1 }
        iter2 = { i: 0, m: matrix2 }

        loop do
          # Take from matrix1 unless we have a translation
          while iter1[:i] < iter1[:m].length and iter1[:m][iter1[:i]][:translation].empty?
            matrix << iter1[:m][iter1[:i]]
            iter1[:i] += 1
          end

          # Take from matrix2 unless we have an original
          while iter2[:i] < iter2[:m].length and iter2[:m][iter2[:i]][:original].empty?
            matrix << iter2[:m][iter2[:i]]
            iter2[:i] += 1
          end

          if iter1[:i] < iter1[:m].length and iter2[:i] < iter2[:m].length
            # Now the two should match provided alignments are sorted the same way,
            # so take one from each. If they don't match outright, we may have a case
            # of swapped sentence orders or a gap (one sentence unaligned in one of
            # the texts surrounded by two sentences that are aligned to the same
            # sentence in the other text). We'll try to repair this by merging bits
            # from the next row in various combinations.
            #
            # When adding to the new mateix, pick original from matrix1 and
            # translation from matrix2 so that the original textual order is
            # preserved
            if repair(matrix, iter1, 0, iter2, 0) or

               repair(matrix, iter1, 1, iter2, 0) or
               repair(matrix, iter1, 0, iter2, 1) or
               repair(matrix, iter1, 1, iter2, 1) or

               repair(matrix, iter1, 2, iter2, 0) or
               repair(matrix, iter1, 0, iter2, 2) or
               repair(matrix, iter1, 2, iter2, 1) or
               repair(matrix, iter1, 1, iter2, 2) or
               repair(matrix, iter1, 2, iter2, 2) or

               repair(matrix, iter1, 3, iter2, 0) or
               repair(matrix, iter1, 0, iter2, 3) or
               repair(matrix, iter1, 3, iter2, 1) or
               repair(matrix, iter1, 1, iter2, 3) or
               repair(matrix, iter1, 3, iter2, 2) or
               repair(matrix, iter1, 2, iter2, 3) or
               repair(matrix, iter1, 3, iter2, 3) or

               repair(matrix, iter1, 4, iter2, 0) or
               repair(matrix, iter1, 0, iter2, 4) or
               repair(matrix, iter1, 4, iter2, 1) or
               repair(matrix, iter1, 1, iter2, 4) or
               repair(matrix, iter1, 4, iter2, 2) or
               repair(matrix, iter1, 2, iter2, 4) or
               repair(matrix, iter1, 4, iter2, 3) or
               repair(matrix, iter1, 3, iter2, 4) or
               repair(matrix, iter1, 4, iter2, 4)
            else
              STDERR.puts iter1[:i], iter1[:m][iter1[:i]].inspect
              STDERR.puts iter2[:i], iter2[:m][iter2[:i]].inspect
              raise
            end
          else
            raise unless iter1[:i] == iter1[:m].length and iter2[:i] == iter2[:m].length
            break
          end
        end

        if log_directory
          File.open(File.join(log_directory, "#{source.id}3"), 'w') do |f|
            matrix.map do |x|
              f.puts x.inspect
            end
          end
        end

        raise unless matrix.map { |r| r[:original]    }.flatten.compact == alignment.sentences.map(&:id)
        raise unless matrix.map { |r| r[:translation] }.flatten.compact == source.sentences.map(&:id)

        matrix
      end

      private

      def self.group_forwards(alignment, source, blacklist = [])
        # Make an original to translation ID mapping
        mapping = {}

        source.sentences.each do |sentence|
          mapping[sentence.id] = []

          next if blacklist.include?(sentence.id)

          mapping[sentence.id] = sentence.inferred_alignment(alignment).map(&:id)
        end

        # Translate to a pairs of ID arrays, chunk original IDs that share at least
        # one translation ID, then reduce the result so we get an array of m-to-n
        # relations
        mapping.map do |v, k|
          { original: k, translation: [v] }
        end.chunk_while do |x, y|
          !(x[:original] & y[:original]).empty?
        end.map do |chunk|
          chunk.inject do |a, v|
            a[:original] += v[:original]
            a[:translation] += v[:translation]
            a
          end
        end.map do |row|
          { original: row[:original].uniq, translation: row[:translation] }
        end
      end

      def self.group_backwards(alignment, source, blacklist = [])
        # Make an original to translation ID mapping
        mapping = {}

        alignment.sentences.each do |sentence|
          mapping[sentence.id] = []
        end

        source.sentences.each do |sentence|
          next if blacklist.include?(sentence.id)

          original_ids = sentence.inferred_alignment(alignment).map(&:id)

          original_ids.each do |original_id|
            mapping[original_id] << sentence.id
          end
        end

        # Translate to a pairs of ID arrays, chunk original IDs that share at least
        # one translation ID, then reduce the result so we get an array of m-to-n
        # relations
        mapping.map do |k, v|
          { original: [k], translation: v }
        end.chunk_while do |x, y|
          !(x[:translation] & y[:translation]).empty?
        end.map do |chunk|
          chunk.inject do |a, v|
            a[:original] += v[:original]
            a[:translation] += v[:translation]
            a
          end
        end.map do |row|
          { original: row[:original], translation: row[:translation].uniq }
        end
      end

      def self.repair_merge_cells(iter, delta, field)
        matrix, i = iter[:m], iter[:i]
        (0..delta).map { |j| matrix[i + j][field] }.inject(&:+)
      end

      def self.select_unaligned(iter, delta, field, check_field)
        matrix, i = iter[:m], iter[:i]
        (0..delta).select { |j| matrix[i + j][check_field].empty? }.map { |j| matrix[i + j][field] }.flatten
      end

      def self.repair(matrix, iter1, delta1, iter2, delta2)
        o1 = repair_merge_cells(iter1, delta1, :original)
        o2 = repair_merge_cells(iter2, delta2, :original)

        t1 = repair_merge_cells(iter1, delta1, :translation)
        t2 = repair_merge_cells(iter2, delta2, :translation)

        u1 = select_unaligned(iter1, delta1, :original, :translation)
        u2 = select_unaligned(iter2, delta2, :translation, :original)

        if o1.sort - u1 == o2.sort.uniq and t1.sort.uniq == t2.sort - u2
          unless delta1.zero? and delta2.zero?
            STDERR.puts "Assuming #{delta1 + 1}/#{delta2 + 1} swapped sentence order:"
            STDERR.puts ' * ' + (0..delta1).map { |j| iter1[:m][iter1[:i] + j].inspect }.join(' + ')
            STDERR.puts ' * ' + (0..delta2).map { |j| iter2[:m][iter2[:i] + j].inspect }.join(' + ')
          end

          matrix << { original: o1, translation: t2 }

          iter1[:i] += delta1 + 1
          iter2[:i] += delta2 + 1

          true
        else
          false
        end
      end
    end
  end
end
