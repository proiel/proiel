#--
#
# aligned_unit.rb - Token alignment within Bible verses
#
# Copyright 2009 University of Oslo
# Copyright 2009 Dag Haug
# Copyright 2017 Marius L. Jøhndal
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

# An aligned unit is a set of token alignments within two larger
# aligned units, e.g. based on verses or sentence alignments. The
# smaller the unit is, the more likely the token alignments are to be
# correct

require 'memoize'
include Memoize

GRC = 'grc'

class AlignedUnit < Hash
  POS_DISTANCES = {
    :a => {:a => 0 , :c => 50, :d => 15, :f => 50, :g => 50, :i => 30, :m => 5, :n => 5, :p => 5, :r => 30, :s => 50, :v => 20 },
    :c => {:a => 50, :c => 0, :d => 5, :f => 50, :g => 20, :i => 50, :m => 50, :n => 50, :p => 50, :r => 20, :s => 50, :v => 50},
    :d => {:a => 15, :c => 5, :d => 0, :f => 50, :g => 15, :i => 50, :m => 50, :n => 50, :p => 50, :r => 5, :s => 50, :v => 30},
    :f => {:a => 50, :c => 50, :d => 50, :f => 50, :g => 50, :i => 50, :m => 50, :n => 50, :p => 50, :r => 50, :s => 50, :v => 50},
    :g => {:a => 50, :c => 20, :d => 15, :f => 50, :g => 0 , :i => 50, :m => 50, :n => 50, :p => 50, :r => 15, :s => 50, :v => 50},
    :i => {:a => 30, :c => 50, :d => 20, :f => 50, :g => 50, :i => 0, :m => 50, :n => 20, :p => 50, :r => 50, :s => 50, :v => 20},
    :m => {:a => 20, :c => 50, :d => 50, :f => 50, :g => 50, :i => 50, :m => 0, :n => 20, :p => 20, :r => 50, :s => 50, :v => 50},
    :n => {:a => 10, :c => 50, :d => 20, :f => 50, :g => 50, :i => 50, :m => 20, :n => 0, :p => 20, :r => 30, :s => 50, :v => 30},
    :p => {:a => 10, :c => 50, :d => 50, :f => 50, :g => 50, :i => 50, :m => 50, :n => 20, :p => 0, :r => 50, :s => 50, :v => 20},
    :r => {:a => 30, :c => 50, :d => 20, :f => 50, :g => 50, :i => 50, :m => 50, :n => 30, :p => 50, :r => 0, :s => 50, :v => 20},
    :s => {:a => 50, :c => 50, :d => 50, :f => 50, :g => 50, :i => 50, :m => 50, :n => 50, :p => 10, :r => 50, :s => 50, :v => 50},
    :v => {:a => 20, :c => 50, :d => 30, :f => 50, :g => 50, :i => 20, :m => 50, :n => 30, :p => 20, :r => 20, :s => 50, :v => 0}
  }

  # We need two arrays of words to be aligned and
  # Lingua::Collocations object to set the alignments
  def initialize(owordarray, twordarray, dict, identifier = nil, verbose = false, report_changes = true)
    @o_avail = owordarray
    twordarray.each { |tw| self[tw] = nil } #Unnecessary?
    @dict = dict
    @identifier = identifier
    @position = {}
    @changes = (report_changes ? :high : :low )
    @verbose = verbose
    @blacklist = []
    @duplications = owordarray + twordarray
    (owordarray.uniq + twordarray.uniq).each { |l| @duplications.delete_at(@duplications.index(l)) }
    @iscores = {}
    owordarray.each_with_index { |item, index| @position[item] = index }
    twordarray.each_with_index { |item, index| @position[item] = index }

    initial_alignment
    #Then align the best pair available, breaking the process if the score is over 35
    while true
      score, ow, tw = find_alignment
      break if score == nil or score > 36
      align(ow, tw)
    end
  end

  # Returns a string representation of the alignments
  def to_s
    s = "\n*****************************************\nAlignments for #{@identifier}\n****************************************\n"
    self.sort { |x,y| @position[x[0]] <=> @position[y[0]] }.each do |alignment|
      s += alignment[0].form + "\t\t"
      s += "\t" if alignment[0].form.size < 15
      s += alignment[1].form + "(#{@position[alignment[1]]})" if alignment[1]
      s += "\n"
    end
    s += "****************************************"
    s += "\nRemaining original words: "
    if @o_avail
      s += @o_avail.collect {|t| t.form + "(#{@position[t]})"}.join(",")
    else
      s += "None"
    end
    s += "\n****************************************\n"
    return s
  end

  # Returns a csv string of the alignments, with each line containing
  # a translation token and its supposed equivalent in the original
  # (or nil if the token is judged not to have an equivalent)
  def to_csv
    s = ''
    self.sort { |x,y| @position[x[0]] <=> @position[y[0]] }.each do |alignment|
    tw, ow = alignment
      s += tw.id.to_s + ","
      if ow
        s += ow.id.to_s
      else
        s += "nil"
      end
      s += "\n"
    end
    s
  end

  # saves the alignments to the database
  def save!
    Token.transaction do
      self.each do |tword, oword|
        raise "#{tword.form} is a Greek word" if tword.language == GRC
        unless tword.automatic_token_alignment == false
          unless oword
            log(@changes) {STDERR.puts "#{tword.form} (#{tword.id}) is now unaligned (used to be aligned to #{tword.token_alignment.form} (#{tword.token_alignment_id}))" if tword.token_alignment_id }
            tword.token_alignment_id = nil
            tword.automatic_token_alignment = true
            tword.save!
          else
            raise "#{oword.form} is not a Greek word" unless oword.language == GRC
            log(@changes) {STDERR.puts "Changed alignment: #{tword.form} (#{tword.id}) belongs to #{oword.form} (#{oword.id}) (used to be #{tword.token_alignment ? tword.token_alignment.form : nil} (#{tword.token_alignment_id}))" unless oword.id == tword.token_alignment_id }
            tword.token_alignment_id = oword.id
            tword.automatic_token_alignment = true
            tword.save!
          end
        end
      end
    end
  end

  private

  def log(priority = :low)
    yield if @verbose or priority == :high
  end

  #returns true if there is another instance of the same lemma among the unaligned t-words
  def duplicated?(word)
    @duplications.include?(word)
  end

  def grab_major_from_lemma(l)
    l.split(':').last[0]
  end

  def initial_alignment
    #Align all tokens occurring within 1 index from a first rank candidate
    self.each_key do |tw|
      raise "No nil objects should occur in initial alignment" if tw == nil
      anchor = find_nearest_anchor(tw)
      if anchor
        index = @position[tw]-@position[anchor[0]]+@position[anchor[1]]
      else
        index = @position[tw]
      end
      #find those neighbouring indices where there is still an available Greek word
      indices = [index, index +1, index -1 ].select { |i| @o_avail[i] and i > -1}
      indices.each do |i|
        if @dict.rank(tw, @o_avail[i]) == 1 and POS_DISTANCES[grab_major_from_lemma(tw).downcase.to_sym][grab_major_from_lemma(@o_avail[i]).downcase.to_sym] < 45 and self.keys.select { |t| t != tw and t == tw}.size < 1
          align(@o_avail[i], tw) unless duplicated?(tw) or duplicated?(@o_avail[i])
          break
        end
      end
    end
  end

  def align(oword, tword)
    log {STDERR.write("Aligning #{oword.form}(#{oword.id}) and #{tword.form}(#{tword.id})\n")}
    self[tword] = oword
    @o_avail.delete(oword)
    [oword, tword].each { |l| @duplications.delete(l) }
  end

  # returns the nearest already aligned word, or nil if there is none
  # another bottleneck - lots of time spent on sort and select
  def find_nearest_anchor(word)
    candidates = self.select {|k,v| k != word and v != nil}
    candidates.sort { |x, y| (@position[x[0]] - @position[word]).abs <=> (@position[y[0]] - @position[word]).abs }.first
  end

# make greek a constant
  def score(oword, tword)
    #raise "#{tword.form} is a Greek word" if tword.language == GRC
    #raise "#{oword.form} is not a Greek word" unless oword.language == GRC
    log {STDERR.write("Scoring words #{tword.form}(#{tword.id}) and #{oword.form}(#{oword.id}): ")}
    s = invariable_score(oword, tword)
    add_variable_score(s, oword, tword)
  end

  def invariable_score(oword, tword)
    return @iscores[oword][tword] if @iscores[oword] and @iscores[oword][tword]
    @iscores[oword] ||= {}
    #penalizing different pos
    points = POS_DISTANCES[grab_major_from_lemma(tword).downcase.to_sym][grab_major_from_lemma(oword).downcase.to_sym]
    log {STDERR.write("#{POS_DISTANCES[grab_major_from_lemma(tword).downcase.to_sym][grab_major_from_lemma(oword).downcase.to_sym]} points for POS...")}
    #penalizing different relation
    if oword.relation_id != tword.relation_id
      log {STDERR.write("10 for relation...")}
      points += 10
    end
    #extra caution with those hapaxes
    if @dict.frequency(tword.lemma_id) == 1
      log {STDERR.write("20 for hapax...")}
      points += 20
    end
    points += @dict.rank(tword.lemma_id, oword.lemma_id)
    log{STDERR.write("#{@dict.rank(tword.lemma_id, oword.lemma_id)} from the dictionary...Total #{points} ")}
    @iscores[oword][tword] = points
  end

  memoize :invariable_score


  def add_variable_score(points, oword, tword)
    #It's a good idea to wait with the alignment of duplicated lemmata.
    #If the match is good enough they will eventually be aligned anyway
    #Consider double penalty for duplication of both words?
    if duplicated?(tword) or duplicated?(oword)
      log {STDERR.write("10 points for duplication")}
      points += 10
    end
    return 37 if points > 36
    #penalizing different indices
    anchor = find_nearest_anchor(tword) #
    if anchor
      position_points = ((@position[tword] - @position[anchor[0]]) - (@position[oword] - @position[anchor[1]])).abs
    else
      position_points = (@position[tword] - @position[oword]).abs * 3
    end
    log {STDERR.write("#{position_points} for position...")}
    return 37 if points + position_points > 36
    #penalizing crossing alignments
    crossed_alignments =  self.select { |tw, ow|  ow != nil and ((@position[tw] > @position[tword] and @position[ow] < @position[oword]) or  (@position[tw] < @position[tword] and @position[ow] > @position[oword])) }
    position_points *= (crossed_alignments.size + 1)
    log{STDERR.write("multiplied by #{crossed_alignments.size + 1} ")}
    crossed_alignments.each {|k,v| log {STDERR.write("(" + k.form + " and " + v.form + ")") } }
    log{STDERR.write("...")}
    points + position_points
  end

  def find_alignment
    topscore, alignment = 1000, []
    self.each do |tw, ow|
      if ow == nil
        @o_avail.each do |ow|
          sc = score(ow, tw)
          if sc < topscore
            topscore = sc
            alignment = [sc, ow, tw]
            log {STDERR.write(", which is the best so far in this iteration\n")}
          else
            log {STDERR.write("\n")}
          end
        end
      end
    end
    log {STDERR.write("The best alignment available is #{alignment[2].form} and #{alignment[1].form} at #{alignment[0].to_s} points\n")} unless alignment == []
    log {STDERR.write("The best anchor is #{find_nearest_anchor(alignment[2])[0].form}")} unless alignment == [] or find_nearest_anchor(alignment[2]) == nil
  alignment
  end
end
