module PROIEL::Valency::Arguments
  def self.get_argument_frame(token)
    arguments = collect_arguments(token)
    hoisted_arguments = arguments.map { |a| hoist_dependents(a) }

    a =
      hoisted_arguments.map do |argument|
        { relation: argument.relation }.merge(extract_features(argument))
      end

    PROIEL::Valency::Obliqueness.sort_arguments(a)
  end

  private

  POS_CLASSIFICATION = {
    'R' => :functor,
    'G' => :functor,
    'N' => :nominal,
    'P' => :nominal,
    'A' => :nominal,
    'M' => :nominal,
    'V' => :verbal,
  }

  # Collapses dependents based on features
  def self.collapse_dependents(dependents)
    # Hoist dependents if any of the dependents is a coordinator
    dependents = dependents.map { |d| hoist_dependents(d) }

    # Figure out if all dependents are equivalent for the purposes of
    # argument frames. Typical examples would be coordinated, identical
    # prepositions (which is operationalised as same lemma, same POS, no
    # case) or coordinated nouns in the same case (which is operationalised
    # as same major POS, same case). If we fail to figure out a way to
    # hoist and reduce arguments, we keep the coordinator.
    majors = dependents.map { |d| POS_CLASSIFICATION[d.part_of_speech_hash[:major] || d.empty_token_sort] }.uniq
    majors = majors.length == 1 ? majors.first : nil

    case majors
    when :functor
      lemmas = dependents.map(&:lemma).uniq
      if lemmas.length == 1
        dependents.first
      else
        #STDERR.puts "Different lemmas R/G: #{lemmas.inspect}"
        nil
      end
    when :nominal
      cases = dependents.map { |d| d.morphology_hash[:case] }.uniq
      if cases.length == 1
        dependents.first
      else
        #STDERR.puts "Different cases N/P: #{cases.inspect}"
        nil
      end
    when :verbal
      moods = dependents.map { |d| d.morphology_hash[:mood] }.uniq
      if moods.length == 1
        dependents.first
      else
        #STDERR.puts "Different moods V: #{moods.inspect}"
        nil
      end
    else
      #STDERR.puts "Unknown combination: #{dependents.map(&:pos).inspect}"
      nil
    end
  end

  # Hoists the real argument dependents from conjoined arguments
  def self.hoist_dependents(argument)
    if argument.part_of_speech == 'C-' or argument.empty_token_sort == 'C'
      # Pick dependents that have the same relation as the coordinator. This
      # eliminates auxiliary elements like particles and repeated
      # conjunctions as well as attributes that scope over all conjuncts.
      dependents = argument.dependents.select { |d| d.relation == argument.relation }

      collapse_dependents(dependents) || argument
    else
      argument
    end
  end

  # Extracts morphosyntactic features that are relevant to the argument frame
  def self.extract_features(argument)
    {}.tap do |features|
      case argument.part_of_speech_hash[:major]
      when 'G'
        features[:lemma] = argument.lemma
        features[:part_of_speech] = argument.part_of_speech

        # There may be multiple dependents and dependents may be headed by
        # coordinators. All relevant dependents have the relation PRED.
        dependents = argument.dependents.select { |d| d.relation == 'pred' }.map { |a| hoist_dependents(a) }
        local_argument = collapse_dependents(dependents)
        features[:mood] = local_argument.morphology_hash[:mood] if local_argument and local_argument.morphology_hash[:mood]
      when 'R'
        features[:lemma] = argument.lemma
        features[:part_of_speech] = argument.part_of_speech

        # There may be multiple dependents and dependents may be headed by
        # coordinators. All relevant dependents have the relation OBL.
        dependents = argument.dependents.select { |d| d.relation == 'obl' }.map { |a| hoist_dependents(a) }
        local_argument = collapse_dependents(dependents)
        features[:case] = local_argument.morphology_hash[:case] if local_argument and local_argument.morphology_hash[:case]
      when 'V'
        features[:mood] = argument.morphology_hash[:mood] if argument.morphology_hash[:mood]
      when 'D'
        features[:lemma] = argument.lemma
        features[:part_of_speech] = argument.part_of_speech
      when 'P'
        features[:case] = argument.morphology_hash[:case] if argument.morphology_hash[:case]
        if argument.part_of_speech == 'Pk' # reflexive personal pronoun
          features[:lemma] = argument.lemma
          features[:part_of_speech] = argument.part_of_speech
        end
      else
        features[:case] = argument.morphology_hash[:case] if argument.morphology_hash[:case]
      end
    end
  end

  # Determines the arguments of a predicate
  def self.collect_arguments(token)
    token.dependents.select do |dependent|
      case dependent.relation
      when 'obj', 'obl', 'xobj', 'comp', 'narg' # arguments
        true
      when 'aux', 'sub', 'ag', 'adv', 'xadv', 'apos', 'atr', 'part', 'expl' # non-arguments
        false
      when 'arg' # unspecific but always an argument
        true
      when 'adnom', 'nonsub', 'per' # unspecific and undetermined with respect to argumenthood
        false
      when 'rel' # unspecific but never an argument
        false
      when 'pred', 'parpred', 'voc' # shouldn't happen
        false
      when 'pid', 'xsub' # really shouldn't happen
        false
      else
        raise "unknown relation #{dependent.relation.inspect}"
      end
    end
  end
end
