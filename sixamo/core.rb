module Sixamo
  class Core
    def initialize(dirname)
      @dic = Dictionary.load(dirname)
    end

    def talk(str = nil, weight = {})
      if str
        keywords = @dic.split_into_keywords(str)
      else
        keywords = Hash.new(0)

        @dic.text.last(10).each do |str|
          keywords.each { |k, v| keywords[k] *= 0.5 }
          @dic.split_into_keywords(str).each { |k, v| keywords[k] += v }
        end
      end

      weight.keys.each do |kw|
        if keywords.key?(kw)
          if weight[kw] == 0
            keywords.delete(kw)
          else
            keywords[kw] *= weight[kw]
          end
        end
      end

      if $DEBUG
        sum = keywords.values.sum
        tmp = keywords.sort_by { |k, v| [-v, k] }
        puts "-(term)----"

        tmp.each do |k, v|
          printf " %s(%6.3f%%), ", k, v / sum * 100
        end

        puts "\n----------"
      end
      message_markov(keywords)
    end

    def memorize(lines)
      @dic.store_text(lines)
      if @dic.learn_from_text
        @dic.save_dictionary
      end
    end

    def message_markov(keywords)
      lines = []
      if keywords.size > 0
        if keywords.size > 10
          keywords.sort_by { |k, v| -v }[10 .. -1].each do |k, v|
            keywords.delete(k)
          end
        end
        sum = keywords.values.sum
        if sum > 0
          keywords.each { |k, v| keywords[k] = v / sum }
        end

        keywords.keys.map do |kw|
          ary = @dic.lines(kw).sort_by { rand }

          ary[0, 10].each do |idx|
            lines << idx
          end
        end.flatten
      end

      10.times do
        lines << rand(@dic.text.size)
      end

      lines.uniq!

      source = lines.map do |k, v|
        @dic.text[k, 5]
      end.sort_by { rand }.flatten.compact.uniq

      msg = Util.markov(source, keywords, @dic.trie)
      Util.message_normalize(msg)
    end
  end
end
