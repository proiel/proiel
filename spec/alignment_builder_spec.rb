require 'spec_helper'

describe PROIEL::Alignment::Builder do
  describe '.compute_matrix' do
    it 'computes alignment matrix for simple 1-to-1 alignment' do
      tb = PROIEL::Treebank.new

      # Define Source A (The "alignment" / original text)
      source_a = PROIEL::Source.new(tb, 'src_a', nil, 'lat', nil, {}, nil) do |src|
        [
          PROIEL::Div.new(src, 1, nil, nil, nil, nil) do |div|
            [
              PROIEL::Sentence.new(div, 100, :annotated, nil, nil, nil, nil, nil, nil, nil) do |sent|
                [
                  PROIEL::Token.new(sent, 1000, nil, 'A', 'a', 'N-', nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], nil)
                ]
              end
            ]
          end
        ]
      end

      # Define Source B (The "source" / translation text) which aligns to Source A
      source_b = PROIEL::Source.new(tb, 'src_b', nil, 'eng', nil, {}, 'src_a') do |src|
        [
          PROIEL::Div.new(src, 2, nil, nil, nil, nil) do |div|
            [
              PROIEL::Sentence.new(div, 200, :annotated, nil, nil, nil, nil, nil, nil, nil) do |sent|
                [
                  # Token aligns to token 1000 in source A
                  PROIEL::Token.new(sent, 2000, nil, 'B', 'b', 'N-', nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, [], 1000)
                ]
              end
            ]
          end
        ]
      end

      # Manually register and index sources as we are bypassing load_from_xml
      tb.sources << source_a
      tb.sources << source_b
      tb.send(:index_source_objects!, source_a)
      tb.send(:index_source_objects!, source_b)

      matrix = PROIEL::Alignment::Builder.compute_matrix(source_a, source_b)

      expect(matrix).to be_a(Array)
      expect(matrix.size).to eq(1)
      expect(matrix.first[:original]).to eq([100])
      expect(matrix.first[:translation]).to eq([200])
    end
  end
end
