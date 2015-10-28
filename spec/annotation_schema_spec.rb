#--
# Copyright (c) 2015 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
require 'spec_helper'

describe PROIEL::AnnotationSchema do
  before(:each) do
    tb = PROIEL::Treebank.new()
    tb.load_from_xml(test_file('dummy-proiel-xml-2.0.xml'))
    @as = tb.annotation_schema
  end

  context 'with a standard treebank loaded' do
    it 'returns all relation tags' do
      expect(@as.relation_tags.class).to eql(Hash)
      expect(@as.relation_tags.keys.sort).to eql(["adnom", "adv", "ag", "apos", "arg", "atr", "aux", "comp", "expl", "narg", "nonsub", "obj", "obl", "parpred", "part", "per", "pid", "pred", "rel", "sub", "voc", "xadv", "xobj", "xsub"])
    end

    it 'returns summaries for relation tags' do
      expect(@as.relation_tags["adv"].summary).to eql("adverbial")
    end

    it 'distinguishes primary and secondary relations' do
      expect(@as.primary_relations.class).to eql(Hash)
      expect(@as.secondary_relations.class).to eql(Hash)

      primary_keys = @as.primary_relations.keys
      expect(primary_keys.sort).to eql(["adnom", "adv", "ag", "apos", "arg", "atr", "aux", "comp", "expl", "narg", "nonsub", "obj", "obl", "parpred", "part", "per", "pred", "rel", "sub", "voc", "xadv", "xobj"])

      secondary_keys = @as.secondary_relations.keys
      expect(secondary_keys.sort).to eql(["adnom", "adv", "ag", "apos", "arg", "atr", "aux", "comp", "expl", "narg", "nonsub", "obj", "obl", "parpred", "part", "per", "pid", "pred", "rel", "sub", "voc", "xadv", "xobj", "xsub"])

      @as.relation_tags.each do |k, v|
        expect(v.primary).to eql(primary_keys.include?(k))
        expect(v.secondary).to eql(secondary_keys.include?(k))
      end
    end

    it 'returns all part of speech tags' do
      expect(@as.part_of_speech_tags.class).to eql(Hash)
      expect(@as.part_of_speech_tags.keys.sort).to eql(["A-", "C-", "Df", "Dq", "Du", "F-", "G-", "I-", "Ma", "Mo", "N-", "Nb", "Ne", "Pc", "Pd", "Pi", "Pk", "Pp", "Pr", "Ps", "Pt", "Px", "Py", "R-", "S-", "V-", "X-"])
    end

    it 'returns summaries for part of speech tags' do
      expect(@as.part_of_speech_tags["Pk"].summary).to eql("personal reflexive pronoun")
    end

    it 'returns all information status tags' do
      expect(@as.information_status_tags.class).to eql(Hash)
      expect(@as.information_status_tags.keys.sort).to eql(["acc_gen", "acc_inf", "acc_sit", "info_unannotatable", "kind", "new", "no_info_status", "non_spec", "non_spec_inf", "non_spec_old", "old", "old_inact", "quant"])
    end

    it 'returns summaries for information status tags' do
      expect(@as.information_status_tags["acc_inf"].summary).to eql("acc-inf")
    end
  end
end
