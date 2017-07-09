# "Set token alignments. Options: SOURCE=source_id or SOURCE_DIVISION=source_division_id, FORMAT={human|csv|db}, FILE=outfile DICTIONARY=dictionary file"

require_relative 'token_aligner'
require_relative 'aligned_unit'
require_relative 'collocations'

format = 'db'
dictionary = Lingua::Collocations.new('latin.dct')

source = ENV['SOURCE']
source_division = ENV['SOURCE_DIVISION']
raise "You can't specify both SOURCE and SOURCE_DIVISION" if source and source_division

sds = Source.find(source).source_divisions

ta = TokenAligner.new(dictionary, format, sds, 'outfile.csv')
ta.execute(aligned_source)
