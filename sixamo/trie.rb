module Sixamo
  class Trie
    def initialize(ary = nil)
      @root = {}
      if ary
        ary.each do |elm|
          self.add(elm)
        end
      end
    end

    def add(str)
      node = @root

      str.each_byte do |b|
        if !node.key?(b)
          node[b] = {}
        end
        node = node[b]
      end

      node[:terminate] = true
    end

    def member?(str)
      node = @root

      str.each_byte do |b|
        return false unless node.key?(b)
        node = node[b]
      end

      node.key?(:terminate)
    end

    def members
      members_sub(@root)
    end

    def members_sub(node, str = '')
      node.map do |k, v|
        if k == :terminate
          str
        else
          members_sub(v, str + k.chr)
        end
      end.flatten
    end
    private :members_sub

    def split_into_terms(str, num = nil)
      result = []
      return result unless str
      while str.size > 0 && ( !num.kind_of?(Numeric) || result.size < num )
        prefix = longest_prefix_subword(str)
        if prefix
          result << prefix
          str = str[prefix.size .. -1]
        else
          chr = /./m.match(str)[0]
          result << chr if num
          str = Regexp.last_match.post_match
        end
      end
      result
    end

    def longest_prefix_subword(str)
      node = @root
      result = nil
      idx = 0

      str.each_byte do |b|
        result = str[0, idx] if node.key?(:terminate)
        return result unless node.key?(b)
        node = node[b]
        idx += 1
      end

      if node.key?(:terminate)
        str
      else
        result
      end
    end

    def delete(str)
      node = @root
      ary = []

      str.each_byte do |b|
        return false unless node.key?(b)
        ary << [node, b]
        node = node[b]
      end

      return false unless node.key?(:terminate)
      ary << [node, :terminate]

      ary.reverse.each do |node, b|
        node.delete(b)
        break unless node.empty?
      end

      true
    end
  end
end
