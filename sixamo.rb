lib = File.expand_path('..', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

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
    dic = Dictionary.new(dirname)
    dic.load_text
    dic.learn_from_text(true)
    dic
  end
end
