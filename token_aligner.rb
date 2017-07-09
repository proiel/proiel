#!/usr/bin/env ruby
#--
#
# token_aligner.rb - Token alignment within Bible verses
#
# Copyright 2009 University of Oslo
# Copyright 2009 Dag Haug
#
# This file is part of the PROIEL web application.
#
# The PROIEL web application is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# The PROIEL web application is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the PROIEL web application.  If not, see
# <http://www.gnu.org/licenses/>.
#
#++

ORIG_SOURCE = 1
LIMIT = 10000000

class TokenAligner
  def initialize(dictionary, format, sds, out = STDOUT)
    @out = File.open(out, "w") unless out == STDOUT
    @out = STDOUT if out == STDOUT
    @format = format.to_sym
    raise "Unknown format" unless [:csv, :human, :db].include?(@format)
    @sds = sds
    @d = dictionary
  end

  def execute(aligned_source)
    @sds.each do |sd|
      #Find the aligned sd if it exists
      original_sd = sd.alignment(aligned_source)

      if original_sd
        ttokens_by_verse = collect_sd(sd)

        unless ttokens_by_verse.empty?
          otokens_by_verse = collect_sd(original_sd)

          (ttokens_by_verse.keys & otokens_by_verse.keys).sort.each do |v|
            STDERR.write("Processing verse #{v} of #{sd.title}...\n")
            reference = "#{sd.title}:#{v}"
            a = AlignedUnit.new(otokens_by_verse[v], ttokens_by_verse[v], @d, reference)
            #process options
            @out.write(a.to_csv) if @format == :csv
            @out.write(a.to_s) if @format == :human
            a.save! if @format == :db
          end
        end
      end
    end
    @out.close unless @out == STDOUT
  end
end

if __FILE__ == $0
  require_relative 'aligned_unit'
  require_relative 'collocations'
  require 'ruby-prof'
  RubyProf.start

  tb = PROIEL::Treebank.new
  ARGV.each { |filename| tb.load_from_xml(filename) }
  source = tb.find_source('latin-nt')
  aligned_source = tb.find_source('greek-nt')
  sd = source.divs.first

  ta = TokenAligner.new(Lingua::Collocations.new('latin.dct'), :human, [sd])
  ta.execute(aligned_source)
  result = RubyProf.stop
  printer = RubyProf::FlatPrinter.new(result)
  printer.print(STDOUT, 0)
end

