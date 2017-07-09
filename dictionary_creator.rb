require_relative 'collocations'

tb = PROIEL::Treebank.new
ARGV.each { |filename| tb.load_from_xml(filename) }

source = tb.find_source('latin-nt')
aligned_source = tb.find_source('greek-nt')

file = File.open('latin.dct', "w")
d = Lingua::Collocations.new(nil, true, :zvtuuf)

source.divs.each do |sd|
  original_sd = sd.alignment(aligned_source)

  if original_sd
    collect_and_update(d, sd, original_sd)
  else
    STDERR.puts "Skipping unaligned div #{source.id}:#{sd.id}"
  end
end

d.make
d.to_csv(30, nil, file)

STDERR.write(d.equivalents('in:R-'))
