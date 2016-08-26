require 'spec_helper'

describe PROIEL::Visualization::Graphviz do
  it 'finds the default template files' do
    PROIEL::Visualization::Graphviz::DEFAULT_TEMPLATES.each do |t|
      expect(File).to exist(PROIEL::Visualization::Graphviz::template_filename(t.to_sym))
      expect(File).to exist(PROIEL::Visualization::Graphviz::template_filename(t.to_s))
    end
  end
end
