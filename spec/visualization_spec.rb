require 'spec_helper'

describe PROIEL::Visualization::Graphviz do
  it 'finds the default template files' do
    PROIEL::Visualization::Graphviz::DEFAULT_TEMPLATES.each do |t|
      expect(File).to exist(PROIEL::Visualization::Graphviz::template_filename(t.to_sym))
      expect(File).to exist(PROIEL::Visualization::Graphviz::template_filename(t.to_s))
    end
  end

  context 'with a loaded treebank' do
    let(:tb) do
      tb = PROIEL::Treebank.new
      tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))
      tb
    end

    let(:sentence) { tb.sources.first.divs.first.sentences.first }

    PROIEL::Visualization::Graphviz::DEFAULT_TEMPLATES.each do |template|
      next if template == :'aligned-modern' # Requires aligned data

      it "generates DOT for #{template} layout" do
        dot = PROIEL::Visualization::Graphviz.generate(template, sentence, :dot)
        expect(dot).to be_a(String)
        expect(dot).to include('digraph')
      end
    end

    context 'for aligned-modern layout' do
      let(:graph) do
        OpenStruct.new(
          left: [sentence.tokens],
          right: [sentence.tokens],
          alignments: [[sentence.tokens.first.id, sentence.tokens.first.id]]
        )
      end

      it 'generates DOT' do
        dot = PROIEL::Visualization::Graphviz.generate(:'aligned-modern', graph, :dot)
        expect(dot).to be_a(String)
        expect(dot).to include('digraph')
      end
    end
  end
end
