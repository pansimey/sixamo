module Sixamo::Util
  def self.roulette_select(h)
    return nil if h.empty?
    sum = h.values.sum
    return h.keys.sample if sum == 0
    r = rand * sum
    h.each do |key, value|
      r -= value
      return key if r <= 0
    end
    h.keys.sample
  end

  def self.message_normalize(str)
    paren_h = {}
    %w|「」 『』 （） ()|.each do |paren|
      paren.scan(/./) do |ch|
        paren_h[ch] = paren.scan(/./)
      end
    end
    re = /[「」『』()（）]/
    ary = str.scan(re)
    cnt = 0
    paren = ''
    str2 = str.gsub(re) do |ch|
      res = if cnt == ary.size - 1 && ary.size % 2 == 1
              ''
            elsif cnt % 2 == 0
              paren = paren_h[ch][1]
              paren_h[ch][0]
            else
              paren
            end
      cnt += 1
      res
    end
    str2.gsub(/「」/, '')
        .gsub(/（）/, '')
        .gsub(/『』/, '')
        .gsub(/\(\)/, '')
  end

  def self.markov(src, keywords, trie)
    mar = markov_generate(src, trie)
    markov_select(mar, keywords)
  end

  MarkovKeySize = 2

  def markov_generate(src, trie)
    return '' if src.size == 0
    ary = trie.split_into_terms(src.join("\n") + "\n", true)
    size = ary.size
    ary.concat(ary[0, MarkovKeySize + 1])
    table = {}
    size.times do |idx|
      key = ary[idx, MarkovKeySize]
      table[key] = [] unless table.key?(key)
      table[key] << ary[idx + MarkovKeySize]
    end
    uniq = {}
    backup = {}
    table.each do |k, v|
      if v.size == 1
        uniq[k] = v[0]
      else
        backup[k] = table[k].dup
      end
    end
    key = ary[0, MarkovKeySize]
    result = key.join('')
    10000.times do
      if uniq.key?(key)
        str = uniq[key]
      else
        table[key] = backup[key].dup if table[key].size == 0
        idx = rand(table[key].size)
        str = table[key][idx]
        table[key][idx] = nil
        table[key].compact!
      end
      result << str
      key = (key.dup << str)[1, MarkovKeySize]
    end
    result
  end

  def markov_split(str)
    result = []
    while /\A(.{25,}?)([。、．，]+|[?!.,]+[\s　])[ 　]*/.match(str)
      match = Regexp.last_match
      m = match[1]
      m += match[2].gsub(/、/, '。').gsub(/，/, '．') if match[2]
      result << m
      str = match.post_match
    end
    result << str if str.size > 0
    result
  end

  def markov_select(result, keywords)
    tmp = result.split(/\n/) || ['']
    result_ary = tmp.map { |str| markov_split(str) }.flatten.uniq
    result_ary.delete_if { |a| a.size == 0 || /\0/.match(a) }
    result_hash = {}
    trie = Trie.new(keywords.keys)
    result_ary.each do |str|
      terms = trie.split_into_terms(str).uniq
      result_hash[str] = terms.map { |kw| keywords[kw] }.sum || 0
    end
    if $DEBUG
      sum = result_hash.values.sum.to_f
      tmp = result_hash.sort_by { |k, v| [-v, k] }
      puts "-(候補数: #{result_hash.size})----"
      tmp.first(10).each do |k, v|
        printf("%5.2f%%: %s\n", v / sum * 100, k)
      end
    end
    self.roulette_select(result_hash) || ''
  end

  module_function :markov_select, :markov_generate, :markov_split
end
