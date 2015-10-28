#--
# Copyright (c) 2015 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
module PROIEL
  # An object in a treebank.
  #
  # @abstract
  class TreebankObject
    # Returns a string containing a human-readable representation of the object.
    #
    # This implementation provides only minimal information about the object
    # and prevents (potentially infinite) recursion into the object tree.
    #
    # @return [String]
    def inspect
      "#<#{self.class} @id=#{id.inspect}>"
    end
  end
end
