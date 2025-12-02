$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'proiel'

def open_test_file(filename)
  File.open(test_file(filename))
end

def test_file(filename)
  File.join(File.dirname(__FILE__), filename)
end
