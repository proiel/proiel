module PROIEL::Valency::Obliqueness
  # Sorts frames by obliqueness
  def self.sort_frames(frames)
    # Sort frames by obliqueness, then by inspecting them so that we get
    # a stable, reproducible order.
    frames.sort_by { |frame| [obliqueness_of_arguments(frame[:arguments]).sort, frame.inspect] }
  end

  # Sorts arguments by obliqueness
  def self.sort_arguments(arguments)
    arguments.sort_by { |argument| obliqueness_of_argument(argument) }
  end

  private

  def self.obliqueness_of_arguments(arguments)
    arguments.map do |argument|
      obliqueness_of_argument(argument)
    end
  end

  def self.obliqueness_of_argument(argument)
    obliqueness_of_relation(argument[:relation]) * 2 + (argument[:lemma].nil? ? 0 : 1)
  end

  OBLIQUENESS_HIERARCHY = %w(sub ag obj xobj arg obl comp narg)

  def self.obliqueness_of_relation(relation)
    OBLIQUENESS_HIERARCHY.index(relation) || OBLIQUENESS_HIERARCHY.length
  end
end
