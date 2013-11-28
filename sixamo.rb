$LOAD_PATH.unshift(__dir__) unless $LOAD_PATH.include?(__dir__)

require 'sixamo/array'
require 'sixamo/util'
require 'sixamo/core'
require 'sixamo/dictionary'
require 'sixamo/freq'
require 'sixamo/trie'

module Sixamo
  def self.new(*args)
    Core.new(*args)
  end

  def self.init_dictionary(dirname)
    dictionary = Dictionary.new(dirname)
    dictionary.load_text
    dictionary.learn_from_text(true)
    dictionary
  end
end
