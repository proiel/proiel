require 'spec_helper'

describe PROIEL::Valency::Obliqueness do
  it 'sorts arguments by the obliqueness of their relations' do
    obl = { relation: 'obl' }
    obj = { relation: 'obj' }
    sub = { relation: 'sub' }

    unsorted_args = [obl, obj, sub]
    sorted_args = [sub, obj, obl]

    expect(PROIEL::Valency::Obliqueness.sort_arguments(unsorted_args)).to eq sorted_args
  end

  it 'sorts an argument with a functor after one without if relations are identical' do
    obl_with_lemma = { relation: 'obl', lemma: 'ad', part_of_speech: 'R-' }
    obl = { relation: 'obl' }
    obj = { relation: 'obj' }
    sub = { relation: 'sub' }

    unsorted_args = [obl_with_lemma, obl, obj, sub]
    sorted_args = [sub, obj, obl, obl_with_lemma]

    expect(PROIEL::Valency::Obliqueness.sort_arguments(unsorted_args)).to eq sorted_args
  end

  it 'sorts frames by the obliqueness of their relations' do
    obl_with_lemma = { relation: 'obl', lemma: 'ad', part_of_speech: 'R-' }
    obl = { relation: 'obl' }
    obj = { relation: 'obj' }

    unsorted_frame1 = { arguments: [obl, obj] }
    unsorted_frame2 = { arguments: [obl] }
    unsorted_frame3 = { arguments: [obl_with_lemma] }

    unsorted_frames = [unsorted_frame3, unsorted_frame1, unsorted_frame2]
    sorted_frames = [unsorted_frame1, unsorted_frame2, unsorted_frame3]

    expect(PROIEL::Valency::Obliqueness.sort_frames(unsorted_frames)).to eq sorted_frames
  end
end

class MockXMLIO < IO
  def initialize(xml)
    @xml = "<proiel export-time='2016-06-16T09:53:13+02:00' schema-version='2.0'><annotation><relations/><parts-of-speech/><morphology/><information-statuses/></annotation><source id='foo'><div id='1'>#{xml}</div></source></proiel>"
  end

  def read
    @xml
  end

  def self.mock_sentence(xml)
    xml = MockXMLIO.new(xml)
    tb = PROIEL::Treebank.new
    tb.load_from_xml(xml).sources.first.sentences.first
  end

  def self.mock_token_in_sentence(xml, token_id)
    s = mock_sentence(xml)
    s.tokens.find { |t| t.id == token_id }
  end
end

describe PROIEL::Valency do
  it 'does something useful' do
    tb = PROIEL::Treebank.new
    tb.load_from_xml(File.join(File.dirname(__FILE__), 'caes-gal.xml'))

    lexicon = PROIEL::Valency::Lexicon.new

    tb.sources.each do |source|
      lexicon.add_source! source
    end

    expect(lexicon.lookup('venio', 'V-')).to eq [{:arguments=>[], :tokens=>{:a=>[681774, 761804, 1190966, 687161, 687167, 687529, 687629, 691442, 692027, 692618, 693685, 693974, 855523, 700502, 709585, 867259, 710327, 710600, 1059668], :r=>[]}}, {:arguments=>[{:relation=>"obl", :case=>"a"}], :tokens=>{:a=>[685156, 713853], :r=>[]}}, {:arguments=>[{:relation=>"obl", :case=>"b"}], :tokens=>{:a=>[1062192], :r=>[]}}, {:arguments=>[{:relation=>"obl", :lemma=>"ab", :part_of_speech=>"R-", :case=>"b"}], :tokens=>{:a=>[686102, 689936, 786018], :r=>[]}}, {:arguments=>[{:relation=>"obl", :lemma=>"ad", :part_of_speech=>"R-", :case=>"a"}], :tokens=>{:a=>[685217, 685724, 685734, 688197, 688396, 689006, 689210, 689713, 758164, 690526, 691222, 692060, 693989, 695672, 698547, 699265, 701354, 701441, 702015, 1052781, 864633, 864664, 1191335, 1057887, 712328], :r=>[]}}, {:arguments=>[{:relation=>"obl", :lemma=>"eo#1", :part_of_speech=>"Df"}], :tokens=>{:a=>[687269, 687302, 689276, 692224, 696320, 855776, 699731, 701828, 701918], :r=>[]}}, {:arguments=>[{:relation=>"obl", :lemma=>"ex", :part_of_speech=>"R-", :case=>"b"}], :tokens=>{:a=>[855411], :r=>[]}}, {:arguments=>[{:relation=>"obl", :lemma=>"huc", :part_of_speech=>"Df"}], :tokens=>{:a=>[701110], :r=>[]}}, {:arguments=>[{:relation=>"obl", :lemma=>"in", :part_of_speech=>"R-", :case=>"a"}], :tokens=>{:a=>[683292, 684977, 685617, 685746, 685826, 865507, 687641, 687663, 690764, 691161, 761958, 695583, 855659, 698830, 856337, 700617, 1052485, 701643, 1057946, 709806, 1058051, 710772, 711825, 1059991, 1060154], :r=>[]}}, {:arguments=>[{:relation=>"obl", :lemma=>"ab", :part_of_speech=>"R-", :case=>"b"}, {:relation=>"obl", :lemma=>"ad", :part_of_speech=>"R-", :case=>"a"}], :tokens=>{:a=>[699658, 699919], :r=>[]}}, {:arguments=>[{:relation=>"obl", :lemma=>"ex", :part_of_speech=>"R-", :case=>"b"}, {:relation=>"obl", :lemma=>"ad", :part_of_speech=>"R-", :case=>"a"}], :tokens=>{:a=>[699776, 864600], :r=>[]}}, {:arguments=>[{:relation=>"obl", :lemma=>"ex", :part_of_speech=>"R-", :case=>"b"}, {:relation=>"obl", :lemma=>"in", :part_of_speech=>"R-", :case=>"a"}], :tokens=>{:a=>[710366], :r=>[]}}]
  end

  it 'identifies two coordinated nominal objects with the same case as a single object' do
    xml = '
      <sentence id="188060" status="reviewed">
        <token id="2150900" form="ꙇ" citation-part="42" lemma="и" part-of-speech="C-" morphology="---------n" head-id="2150903" relation="aux" presentation-after=" " foreign-ids="folio=78v"/>
        <token id="2150901" form="здѣлавъ" citation-part="42" lemma="съдѣлати" part-of-speech="V-" morphology="-supamn-si" head-id="2150903" relation="xadv" presentation-after=" " foreign-ids="folio=78v">
          <slash target-id="2150903" relation="xsub"/>
        </token>
        <token id="2150902" form="ѡкошко" citation-part="42" lemma="окошко" part-of-speech="Nb" morphology="-s---na--i" head-id="2150901" relation="obj" presentation-after=" " foreign-ids="folio=78v"/>
        <token id="2150903" form="дават" citation-part="42" lemma="давати" part-of-speech="V-" morphology="--pna----i" relation="pred" presentation-after=" " foreign-ids="folio=78v"/>
        <token id="2150904" form="хлѣбъ" citation-part="42" lemma="хлѣбъ" part-of-speech="Nb" morphology="-s---ma--i" head-id="2150905" relation="obj" presentation-after=" " foreign-ids="folio=78v"/>
        <token id="2150905" form="ꙇ" citation-part="42" lemma="и" part-of-speech="C-" morphology="---------n" head-id="2150903" relation="obj" presentation-after=" " foreign-ids="folio=78v"/>
        <token id="2150906" form="воду" citation-part="42" lemma="вода" part-of-speech="Nb" morphology="-s---fa--i" head-id="2150905" relation="obj" presentation-after=". " foreign-ids="folio=78v"/>
      </sentence>
    '

    t = MockXMLIO.mock_token_in_sentence(xml, 2150903)
    frame = PROIEL::Valency::Arguments.get_argument_frame(t)
    expect(frame).to eq [{ relation: "obj", case: "a" }]
  end

  it 'hoists the case of a dependent of a preposition' do
    xml = '
      <sentence id="1" status="annotated">
        <token id="250079" form="genuit" citation-part="MATT 1.5" lemma="gigno" part-of-speech="V-" morphology="3sria----i" relation="pred"/>
        <token id="250081" form="ex" citation-part="MATT 1.5" lemma="ex" part-of-speech="R-" morphology="---------n" head-id="250079" relation="obl"/>
        <token id="250082" form="deo" citation-part="MATT 1.5" lemma="deus" part-of-speech="Ne" morphology="-s---mb--i" head-id="250081" relation="obl"/>
      </sentence>
    '

    t = MockXMLIO.mock_token_in_sentence(xml, 250079)
    frame = PROIEL::Valency::Arguments.get_argument_frame(t)
    expect(frame).to eq [{ relation: 'obl', lemma: 'ex', part_of_speech: 'R-', case: 'b' }]
  end

  it 'hoists the mood of coordinated dependents of a subjunction' do
    xml = '
      <sentence id="75892" status="reviewed">
        <token id="1081210" form="abs" citation-part="1.1.4" lemma="ab" part-of-speech="R-" morphology="---------n" head-id="1081212" relation="obl" information-status="info_unannotatable" presentation-after=" "/>
        <token id="1081211" form="te" citation-part="1.1.4" lemma="tu" part-of-speech="Pp" morphology="2s---mb--i" head-id="1081210" relation="obl" antecedent-id="1232225" information-status="old" presentation-after=" "/>
        <token id="1232287" empty-token-sort="P" head-id="1081212" relation="sub" antecedent-id="1232233" information-status="old"/>
        <token id="1081212" form="peto" citation-part="1.1.4" lemma="peto" part-of-speech="V-" morphology="1spia----i" relation="pred" presentation-after=" "/>
        <token id="1081213" form="ut" citation-part="1.1.4" lemma="ut" part-of-speech="G-" morphology="---------n" head-id="1081212" relation="comp" presentation-after=" "/>
        <token id="1081214" form="mihi" citation-part="1.1.4" lemma="ego" part-of-speech="Pp" morphology="1s---md--i" head-id="1081216" relation="obl" antecedent-id="1232287" information-status="old" presentation-after=" "/>
        <token id="1081215" form="hoc" citation-part="1.1.4" lemma="hic" part-of-speech="Pd" morphology="-s---na--i" head-id="1081216" relation="obj" antecedent-id="1081209" information-status="old" presentation-after=" "/>
        <token id="1232235" empty-token-sort="P" head-id="1081216" relation="sub" antecedent-id="1081211" information-status="old"/>
        <token id="1081216" form="ignoscas" citation-part="1.1.4" lemma="ignosco" part-of-speech="V-" morphology="2spsa----i" head-id="1081217" relation="pred" presentation-after=" "/>
        <token id="1081217" form="et" citation-part="1.1.4" lemma="et" part-of-speech="C-" morphology="---------n" head-id="1081213" relation="pred" presentation-after=" "/>
        <token id="1081218" form="me" citation-part="1.1.4" lemma="ego" part-of-speech="Pp" morphology="1s---ma--i" head-id="1081222" relation="sub" antecedent-id="1081214" information-status="old" presentation-after=" "/>
        <token id="1232236" empty-token-sort="P" head-id="1081219" relation="sub" antecedent-id="1232235" information-status="old"/>
        <token id="1081219" form="existimes" citation-part="1.1.4" lemma="existimo" part-of-speech="V-" morphology="2spsa----i" head-id="1081217" relation="pred" presentation-after=" "/>
        <token id="1081220" form="humanitate" citation-part="1.1.4" lemma="humanitas" part-of-speech="Nb" morphology="-s---fb--i" head-id="1081222" relation="adv" information-status="info_unannotatable" presentation-after=" "/>
        <token id="1081221" form="esse" citation-part="1.1.4" lemma="sum" part-of-speech="V-" morphology="--pna----i" head-id="1081222" relation="aux" presentation-after=" "/>
        <token id="1081222" form="prohibitum" citation-part="1.1.4" lemma="prohibeo" part-of-speech="V-" morphology="-srppma--i" head-id="1081219" relation="comp" presentation-after=" "/>
        <token id="1081223" form="ne" citation-part="1.1.4" lemma="ne" part-of-speech="G-" morphology="---------n" head-id="1081222" relation="comp" presentation-after=" "/>
        <token id="1081224" form="contra" citation-part="1.1.4" lemma="contra" part-of-speech="Df" morphology="---------n" head-id="1081231" relation="obl" information-status="info_unannotatable" presentation-after=" "/>
        <token id="1081225" form="amici" citation-part="1.1.4" lemma="amicus" part-of-speech="Nb" morphology="-s---mg--i" head-id="1081227" relation="atr" antecedent-id="1081149" information-status="old" presentation-after=" "/>
        <token id="1081226" form="summam" citation-part="1.1.4" lemma="summus" part-of-speech="A-" morphology="-s---fap-i" head-id="1081227" relation="atr" presentation-after=" "/>
        <token id="1081227" form="existimationem" citation-part="1.1.4" lemma="existimatio" part-of-speech="Nb" morphology="-s---fa--i" head-id="1081224" relation="obl" information-status="new" presentation-after=" "/>
        <token id="1081228" form="miserrimo" citation-part="1.1.4" lemma="miser" part-of-speech="A-" morphology="-s---obs-i" head-id="1081230" relation="atr" presentation-after=" "/>
        <token id="1081229" form="eius" citation-part="1.1.4" lemma="is" part-of-speech="Pp" morphology="3s---mg--i" head-id="1081230" relation="atr" antecedent-id="1081225" information-status="old" presentation-after=" "/>
        <token id="1081230" form="tempore" citation-part="1.1.4" lemma="tempus" part-of-speech="Nb" morphology="-s---nb--i" head-id="1081231" relation="adv" information-status="new" presentation-after=" "/>
        <token id="1232237" empty-token-sort="P" head-id="1081231" relation="sub" antecedent-id="1081218" information-status="old"/>
        <token id="1081231" form="venirem" citation-part="1.1.4" lemma="venio" part-of-speech="V-" morphology="1sisa----i" head-id="1081223" relation="pred" presentation-after=", "/>
        <token id="1081232" form="cum" citation-part="1.1.4" lemma="cum" part-of-speech="G-" morphology="---------n" head-id="1081231" relation="adv" presentation-after=" "/>
        <token id="1081233" form="is" citation-part="1.1.4" lemma="is" part-of-speech="Pp" morphology="3s---mn--i" head-id="1081241" relation="sub" antecedent-id="1081229" information-status="old" presentation-after=" "/>
        <token id="1081234" form="omnia" citation-part="1.1.4" lemma="omnis" part-of-speech="Px" morphology="-p---na--i" head-id="1081237" relation="atr" information-status="info_unannotatable" presentation-after=" "/>
        <token id="1081235" form="sua" citation-part="1.1.4" lemma="suus" part-of-speech="Pt" morphology="3p---na--i" head-id="1081237" relation="atr" information-status="info_unannotatable" presentation-after=" "/>
        <token id="1081236" form="studia" citation-part="1.1.4" lemma="studium" part-of-speech="Nb" morphology="-p---na--i" head-id="1081237" relation="obj" antecedent-id="1081233" information-status="quant" presentation-after=" "/>
        <token id="1081237" form="et" citation-part="1.1.4" lemma="et" part-of-speech="C-" morphology="---------n" head-id="1081241" relation="obj" presentation-after=" "/>
        <token id="1081238" form="officia" citation-part="1.1.4" lemma="officium" part-of-speech="Nb" morphology="-p---na--i" head-id="1081237" relation="obj" antecedent-id="1081233" information-status="quant" presentation-after=" "/>
        <token id="1081239" form="in" citation-part="1.1.4" lemma="in" part-of-speech="R-" morphology="---------n" head-id="1081241" relation="obl" information-status="info_unannotatable" presentation-after=" "/>
        <token id="1081240" form="me" citation-part="1.1.4" lemma="ego" part-of-speech="Pp" morphology="1s---ma--i" head-id="1081239" relation="obl" antecedent-id="1232237" information-status="old" presentation-after=" "/>
        <token id="1081241" form="contulisset" citation-part="1.1.4" lemma="confero" part-of-speech="V-" morphology="3slsa----i" head-id="1081232" relation="pred" presentation-after=". "/>
      </sentence>
    '

    # peto [ab te] [ut [C ignoscas existimes]]
    t = MockXMLIO.mock_token_in_sentence(xml, 1081212)
    frame = PROIEL::Valency::Arguments.get_argument_frame(t)
    expect(frame).to eq [
      { relation: 'obl',  lemma: 'ab', part_of_speech: 'R-', case: 'b' },
      { relation: 'comp', lemma: 'ut', part_of_speech: 'G-', mood: 's' },
    ]
  end
end
