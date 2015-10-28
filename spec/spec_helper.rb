#--
# Copyright (c) 2015 Marius L. Jøhndal
#
# See LICENSE in the top-level source directory for licensing terms.
#++
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'simplecov'
SimpleCov.start

require 'proiel'

def open_test_file(filename)
  File.open(test_file(filename))
end

def test_file(filename)
  File.join(File.dirname(__FILE__), filename)
end
