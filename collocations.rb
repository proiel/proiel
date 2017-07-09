#!/usr/bin/env ruby
#
# collocations.rb - collocation analysis
#
# Copyright 2009 University of Oslo
# Copyright 2009 Dag Haug
# Copyright 2016-2017 Marius L. Jøhndal
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

require 'proiel'

require 'memoize'
include Memoize

module Lingua
  class Collocations

    CALC_LIMIT = 30
    # The following constant is used to return ranks for items that are
    # not among the CALC_LIMIT best correspondences
    PENALTY = 4

    # Start a dictionary based on collocation measures. method = association score method
    def initialize(file = nil, bidirectional = true, method = :zvtuuf)
      @bidirectional = bidirectional
      @method = method
      @made = false
      @lemmata = Hash.new(0)
      @collocates = Hash.new(0)
      @othersign = Hash.new if @bidirectional
      @otherrankings = Hash.new if @bidirectional
      @chunkcounter = 0
      @scores = Hash.new
      @sign = Hash.new
      @counts = Hash.new
      @rankings = Hash.new
      if file
        from_csv(file)
        @made = true
      end
      if @method == :fisher
        require 'rsruby'
        require 'bigdecimal'
        @r = RSRuby.instance
        @r.matrix.autoconvert(RSRuby::NO_CONVERSION) #Hack to avoid auto-conversion of R matrices
      end
    end

    # Updates the counter with new chunks. The function should get an
    # array of one or more arrays, each of which should either contain two
    # atoms or two arrays
    def update(chunks)
      raise "Dictionary already made" if @made
      @chunkcounter += chunks.size
      chunks.each_with_index do |chunk, i|
        raise "Chunk must contain two parallell sets of tokens" unless chunk.size == 2
        tchunk, ochunk = *chunk
        tchunk = [tchunk] unless tchunk.is_a?(Array)
        ochunk = [ochunk] unless ochunk.is_a?(Array)
        raise "This chunk contains nil elements" if tchunk.compact! or ochunk.compact!
        unless (tchunk.empty? or ochunk.empty?)
          tchunk.uniq.each { |word| count_correspondences(word, ochunk, @counts, @lemmata) }
          ochunk.uniq.each { |word| @collocates[word] += 1 }
        end
      end
    end

    # Returns an array of equivalents to word, sorted by rank
    def equivalents(word)
      raise "You must make the dictionary first" unless @made
      @rankings[word]
    end

    def limit
      CALC_LIMIT
    end

    # Closes the dictionary for further updates, calculates log
    # likelihood ratios and ranks the words
    def make
      STDERR.write("Bidirectionality is #{@bidirectional}\n")
      raise "Dictionary already made" if @made

      #We transform the counts into significances
      @lemmata.each_key do |lemma|
        @sign[lemma] ||= {}
        @counts[lemma].each do |collocate, collfreq|
          @sign[lemma][collocate] = calculate_significance(collfreq, (@lemmata[lemma] - collfreq), (@collocates[collocate] - collfreq), (@chunkcounter + collfreq - @lemmata[lemma] - @collocates[collocate]))
          raise "Calculation error!" unless @sign[lemma][collocate] != nil
          if @bidirectional
            @othersign[collocate] ||= {}
            @othersign[collocate][lemma] = @sign[lemma][collocate]
          end
        end
      end

      # Then we rank them
      @significances = {}
      @sign.each do |lemma, entries|
        @significances[lemma] = entries.sort { |x,y| y[1] <=> x[1] }
        # We are not going to use the actual scores, only the relative
        # ranks of the CALC_LIMIT best words
        @significances[lemma].each { |x| x.delete_at(1)}.flatten!
        @significances[lemma] = @significances[lemma][0...CALC_LIMIT]
      end

      if @bidirectional
        @othersignificances = {}
        @othersign.each do |lemma, entries|
          @othersignificances[lemma] = entries.sort { |x,y| y[1] <=> x[1] }
          @othersignificances[lemma].each { |x| x.delete_at(1)}.flatten!
          @othersignificances[lemma] = @othersignificances[lemma][0..CALC_LIMIT]
        end
      end

      # And then we combine the rankings
      i, n = 0, @lemmata.size
      @lemmata.each_key do |tword|
        i += 1
        @rankings[tword] = []
        @scores[tword] = {}
        @significances[tword].each do |oword|
          @rankings[tword].push(oword)
          if @bidirectional
            @scores[tword][oword] = (1/(Math.sqrt(monolingual_rank(@significances, tword, oword) * monolingual_rank(@othersignificances, oword, tword))))
          else
            @scores[tword][oword] = @sign[tword][oword]
          end
        end
        @rankings[tword].sort! { |x,y| @scores[tword][y] <=> @scores[tword][x] }
      end
      @made = true
    end

    # Writes a csv version of the dictionary with each line containing
    # the translation object, its frequency, then a limited number of
    # equivalent objects (and their score). You can pass a block as
    # the form argument, it will be used to format the representation
    # of the objects in the file
    def to_csv(limit = 30, form = nil, out = STDOUT)
      raise "You must make the dictionary first" unless @made
      out.write("Number of chunks = #{@chunkcounter}\n")
      @rankings.each do |lm, entries|
        s = ""
        i = 1
        if form
          s += "#{form.call(lm)}"
        else
          s += "#{lm}"
        end
        s += ",freq=#{@lemmata[lm]},"
        entries.each do |entry|
          break if i > limit
          i += 1
          if form
            s += "#{form.call(entry)}"
          else
            s+= "#{entry}"
          end
          s+= "{cr=#{@scores[lm][entry].to_s};sign=#{@sign[lm][entry].to_s};cooccurs=#{cooccurs(lm, entry).to_s};occurs=#{@collocates[entry]}},"
        end
        s = s.chop! + "\n"
        out.write(s)
      end
      out.close unless out == STDOUT
    end

    # Writes a list of the best pairs in the dictionary
    def ranked_list(form = nil)
      list = []
      @lemmata.each_key do |lm|
        @sign[lm].each do |entry,value|
          list << [[lm,entry], value]
        end
      end
      list.sort! { |x,y| y[1] <=> x[1] }
      list.each do |l|
        t, o = *l[0]
        t = form.call(t) if form
        o = form.call(o) if form
        STDOUT.write("#{t} -- #{o}: #{l[1]}\n")
      end
    end

    # Returns the frequency of an item
    def frequency(tword)
      raise "You must make the dictionary first" unless @made
      STDERR.write("Warning: #{tword} not found in dictionary") if @lemmata[tword] == 0
      @lemmata[tword]
    end

    # Returns the rank of oword as a corrspondence to tword, taking
    # into account the significance of collocations in both directions
    def rank(tword, oword)
      raise "No entry for #{tword}" unless @rankings[tword]
      @rankings[tword].index(oword) ? @rankings[tword].index(oword) + 1 : CALC_LIMIT + PENALTY
    end

    # Returns the rank of oword as a correspondence to tword, ignoring
    # the significance of collocations in the 'other' direction
    def mr(tword, oword)
      raise "#{tword} is not in the dictionary" unless @lemmata.include?(tword)
      monolingual_rank(tword, oword)
    end

    #Returns the number of times two words cooccur
    def cooccurs(tword, oword)
      raise "Dictionary created from file without cooccurrence data" unless @counts
      @counts[tword][oword]
    end

    #Returns the significance (log likelihood) of word cooccurrence
    def significance(tword, oword)
      @sign[tword][oword]
    end

    private

    #Read the dictionary from a CSV-file instead.
    def from_csv(file)
      File.open(file).each_line do |l|
        if l =~ /^Number of chunks/
          @chunkcounter = l.chop!.split("=")[1].to_i
        else
          entries = l.chop!.split(",")
          lemma = entries.shift
          #This will break if there are 0's in the collocations
          lemma = lemma.to_i unless lemma.to_i == 0
          @lemmata[lemma] =  entries.shift.split("=")[1].to_i
          @rankings[lemma] = []
          @scores[lemma] = {}
          @sign[lemma] = {}
          @counts[lemma] = {}
          entries.each do |e|
            translation = e.split("{")[0]
            # This will break if there are 0's in the collocations Is
            # there a better way to ensure that numbers are converted
            # to integers, but everything else is left unchanged?
            translation = translation.to_i unless translation.to_i == 0
            details = e.split("{")[1].chop!
            score, sig, cooc, oc = details.split(";")
            @rankings[lemma].push(translation)
            @scores[lemma][translation] = score.split("=")[1].to_f
            @sign[lemma][translation] = sig.split("=")[1].to_f
            @counts[lemma][translation] = cooc.split("=")[1].to_i
            @collocates[translation] = oc.split("=")[1].to_i
          end
        end
      end
    end

    def count_correspondences(word, alignedchunk, counts, lemmacounter)
      lemmacounter[word] += 1
      counts[word] ||= Hash.new(0)
      alignedchunk.uniq.each { | correspondence| counts[word][correspondence] += 1 }
    end

    # Returns the rank of tword as a correspondence to oword
    def monolingual_rank(list, oword, tword)
      list[oword].index(tword) ? list[oword].index(tword) + 1 : CALC_LIMIT + PENALTY
    end

    # returns the significance of a collocation according to the
    # method specified in @method
    def calculate_significance(o11, o12, o21, o22)
      if @method == :zvtuuf
        zvtuuf(o11, o12, o21, o22)
      elsif @method == :dunning
        dunning(o11, o12, o21, o22)
      elsif @method == :fisher
        fisher(o11, o12, o21, o22)
      else
        raise "Method error"
      end
    end

    # Fisher exact test as computed by the R implementation
    def fisher(o11, o12, o21, o22)
      m = @r.matrix([o11,o12,o21,o22], :nrow => 2, :ncol => 2)
      1 - BigDecimal.new((@r.fisher_test(m, :alternative => "greater")["p.value"]).to_s)
    end

    # log likelihood measure
    # From Cysouw, Biemann and Ongyerth, "Using
    # Strong's Numbers in the Bible to test an automatic alignment of
    # parallel texts", Sprachtypologie und Universalienforschung
    # 60(2007), p. 158-171
    def zvtuuf(o11, o12, o21, o22)
      x = (((o11 + o12)*(o11 + o21)).to_f) / (o11 + o12 + o21 + o22)
      (x - (o11 * Math.log(x)) + logfact(o11)) / Math.log(o11 + o12 + o21 + o22)
    end

    memoize :zvtuuf

    def logfact(k)
      s = 0
      (1..k).each { |x| s += Math.log(x) }
      s
    end

    memoize :logfact

    def dunning(o11, o12, o21, o22)
      return 0 if (o12 == 0 or o21 == 0)
      r1 = o11 + o12
      r2 = o21 + o22
      c1 = o11 + o21
      c2 = o12 + o22
      n = o11 + o12 + o21 + o22
      return 0 if l(o11, c1, o11.to_f/c1) * l(o12, c2, o12.to_f/c2) == 0
      p = (l(o11, c1, r1.to_f/n) * l(o12, c2, r1.to_f/n)) / (l(o11, c1, o11.to_f/c1) * l(o12, c2, o12.to_f/c2))
      Math.log(p) * -2
    end

    memoize :dunning

    def l(k, n, r)
      (r**k)*((1-r)**(n-k))
    end

    memoize :l
  end
end

def collect_sd(sd)
  tokens_by_verse = {}

  sd.tokens.reject { |t| t.lemma.nil? }.each do |t|
    l = [t.lemma, t.pos].join(':')
    if t.citation[/\.(\d+)$/]
      v = $1
      tokens_by_verse[v] ||= []
      tokens_by_verse[v] << l
    else
      raise t.citation
    end
  end

  tokens_by_verse
end

def collect_and_update(d, sd1, sd2)
  ttokens_by_verse, otokens_by_verse = [collect_sd(sd1), collect_sd(sd2)]

  chunks = []

  (ttokens_by_verse.keys & otokens_by_verse.keys).each do |v|
    tverselemmata = ttokens_by_verse[v]
    overselemmata = otokens_by_verse[v]
    chunks << [tverselemmata, overselemmata]
  end

  d.update(chunks)
end

if __FILE__ == $0
  tb = PROIEL::Treebank.new
  ARGV.each { |filename| tb.load_from_xml(filename) }

  sd = tb.find_div(336)
  original_sd = tb.find_div(76)
  d = Lingua::Collocations.new(nil, true)
  collect_and_update(d, sd, original_sd)
  d.make

  # Then write it to a test file
  d.to_csv(5, nil, File.open("testfil.log", "w"))

  # And recreate it from this file and write it to STDOUT
  e = Lingua::Collocations.new("testfil.log")
  e.to_csv(8, nil, STDOUT)

  # And test the rankings function
  STDERR.write(e.equivalents('in:R-'))
end
