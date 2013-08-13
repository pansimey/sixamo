class Sixamo::Dictionary
  TEXT_FILENAME = 'sixamo.txt'
  DIC_FILENAME = 'sixamo.dic'
  LTL = 3
  WindowSize = 500

  def self.load(dirname)
    dic = Dictionary.new(dirname)
    dic.load_text
    dic.load_dictionary
    dic
  end

  def initialize(dirname = nil)
    @occur = {}
    @rel = {}
    @trie = Trie.new
    @dirname = dirname
    @text_filename = "#{@dirname}/#{TEXT_FILENAME}"
    @dic_filename  = "#{@dirname}/#{DIC_FILENAME}"
    @text = []
    @line_num = 0
  end
  attr_reader :text, :trie

  def load_text
    return unless File.readable?(@text_filename)
    File.open(@text_filename) do |file|
      file.each do |line|
        @text << line.chomp
      end
    end
  end

  def load_dictionary
    return unless File.readable?(@dic_filename)
    File.open(@dic_filename) do |file|
      file.each do |line|
        line.chomp!
        case line
        when /^$/
          break
        when /line_num:\s*(.*)\s*$/i
          @line_num = $1.to_i
        else
          STDERR.puts " #{@dic_filename}:[Warning] Unknown_header #{line}"
        end
      end
      GC.disable
      file.each do |line|
        word, num, sum, occur = line.chomp.split(/\t/)
        if occur
          @occur[word] = occur.split(/,/).map { |l| l.to_i }
          add_term(word)
          @rel[word] = Hash.new(0)
          @rel[word][:num] = num.to_i
          @rel[word][:sum] = sum.to_i
        end
      end
      GC.enable
      GC.start
    end
  end

  def save_text
    tmp_filename = "#{@dirname}/sixamo.tmp.#{Process.pid}-#{rand(100)}"
    File.open(tmp_filename, 'w') do |file|
      file.puts(@text)
    end
    File.rename(tmp_filename, @text_filename)
  end

  def save_dictionary
    tmp_filename = "#{@dirname}/sixamo.tmp.#{Process.pid}-#{rand(100)}"
    File.open(tmp_filename, 'w') do |file|
      file.print(self.to_s)
    end
    File.rename(tmp_filename, @dic_filename)
  end

  def learn_from_text(progress = nil)
    modified = false
    read_size = 0
    buf_prev = []
    end_flag = false
    idx = @line_num
    while true
      buf = []
      if progress
        # idx2 = read_size / WindowSize * WindowSize
        idx2 = read_size / WindowSize ** 2
        if idx2 % 100_000 == 0
          STDERR.printf "\n%5dk ", idx2 / 1000
        elsif idx2 % 20_000 == 0
          STDERR.print "*"
        elsif idx2 % 2_000 == 0
          STDERR.print "."
        end
      end
      tmp = read_size
      while tmp / WindowSize == read_size / WindowSize
        if idx >= @text.size
          end_flag = true
          break
        end
        buf << @text[idx]
        tmp += @text[idx].size
        idx += 1
      end
      read_size = tmp
      break if end_flag
      if buf_prev.size > 0
        learn(buf_prev + buf, @line_num)
        modified = true
        @line_num += buf_prev.size
      end
      buf_prev = buf
    end
    STDERR.print "\n" if progress
    modified
  end

  def store_text(lines)
    File.open(@text_filename, 'a') do |file|
      lines.each do |line|
        @text << line.gsub(/\s+/, ' ').strip
        file.puts(@text.last.chomp)
      end
    end
  end

  def learn(lines, idx = nil)
    new_terms = Freq.extract_terms(lines, 30)
    new_terms.each { |term| add_term(term) }
    if idx
      words_all = []
      lines.each_with_index do |line, i|
        num = idx + i
        words = split_into_terms(line)
        words_all.concat(words)
        words.each do |term|
          if @occur[term].empty? || num > @occur[term][-1]
            @occur[term] << num
          end
        end
      end
      weight_update(words_all)
      self.terms.each do |term|
        occur = @occur[term]
        size = occur.size
        if size < 4 && size > 0 && occur[-1] + size * 150 < idx
          del_term(term)
        end
      end
    end
  end

  def split_into_keywords(str)
    result = Hash.new(0)
    split_into_terms(str).each do |term|
      result[term] += self.weight(term)
    end
    result
  end

  def split_into_terms(str, num = nil)
    @trie.split_into_terms(str, num)
  end

  def to_s
    result = ""
    result << "line_num: #{@line_num}\n"
    result << "\n"
    @occur.delete_if { |k, v| v.size == 0 }
    @occur.each { |k, v|  @occur[k] = v[-100 .. -1] if v.size > 100 }
    tmp = @occur.keys.sort_by do |k|
      [-@occur[k].size, @rel[k][:num], k.length, k]
    end
    tmp.each do |k|
      result << format("%s\t\%s\t\%s\t%s\n",
                       k,
                       @rel[k][:num],
                       @rel[k][:sum],
                       @occur[k].join(','))
    end
    result
  end

  def weight_update(words)
    width = 20
    words.each do |term|
      @rel[term] = Hash.new(0) unless @rel.key?(term)
    end
    size = words.size
    (size - width).times do |idx1|
      word1 = words[idx1]
      (idx1+1).upto(idx1+width) do |idx2|
        @rel[word1][:num] += 1 if word1 == words[idx2]
        @rel[word1][:sum] += 1
      end
    end
    (width + 1).times do |idx1|
      word1 = words[-idx1]
      if word1
        (idx1 - 1).downto(1) do |idx2|
          @rel[word1][:num] += 1 if word1 == words[-idx2]
          @rel[word1][:sum] += 1
        end
      end
    end
  end

  def weight(word)
    if !@rel.key?(word) || @rel[word][:sum] == 0
      0
    else
      num = @rel[word][:num]
      sum = @rel[word][:sum].to_f
      num / (sum * (sum + 100))
    end
  end

  def lines(word)
    @occur[word] || []
  end

  def terms
    @occur.keys
  end

  def add_term(str)
    @occur[str] = [] unless @occur.key?(str)
    @trie.add(str)
    @rel[str] = Hash.new(0) unless @rel.key?(str)
  end

  def del_term(str)
    occur = @occur[str]
    @occur.delete(str)
    @trie.delete(str)
    @rel.delete(str)
    tmp = split_into_terms(str)
    tmp.each { |w| @occur[w] = @occur[w].concat(occur).uniq.sort }
    weight_update(tmp) if tmp.size > 0
  end
end
