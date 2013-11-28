module Sixamo
  class Freq
    def self.extract_terms(buf, limit)
      self.new(buf).extract_terms(limit)
    end

    def initialize(buf)
      if buf.kind_of?(Array)
        buf = buf.join("\0")
      end
      @buf = buf
    end

    def extract_terms(limit)
      terms = extract_terms_sub(limit)

      terms = terms.map do |t, n|
        [t.reverse.strip, n]
      end.sort

      terms2 = []

      (terms.size-1).times do |idx|
        if terms[idx][0].size >= terms[idx + 1][0].size ||
            terms[idx][0] != terms[idx + 1][0][0, terms[idx][0].size]
          terms2 << terms[idx]
        elsif terms[idx][1] >= terms[idx + 1][1] + 2
          terms2 << terms[idx]
        end
      end

      if terms.size > 0
        terms2 << terms[-1]
      end

      terms2.map do |t, n|
        t.reverse
      end
    end

    def extract_terms_sub(limit, str = '', num = 1, width = false)
      h = freq(str)
      flag = (h.size <= 4)
      result = []
      if limit > 0
        if h.key?(str)
          h.delete(str)
        end

        h.to_a.delete_if do |k, v|
          v < 2
        end.sort.each do |k, v|
          result.concat(extract_terms_sub(limit - 1, k, v, flag))
        end
      end
      if result.size == 0 && width
        return [[str.downcase, num]]
      end
      result
    end

    def freq(str)
      freq = Hash.new(0)
      if str.size == 0
        regexp = /([!-~])[!-~]*|([ァ-ヴ])[ァ-ヴー]*|([^ー\0])/i

        @buf.scan(regexp) do |ary|
          freq[ary[0] || ary[1] || ary[2]] += 1
        end
      else
        regexp = /#{Regexp.quote(str)}[^\0]?/i

        @buf.scan(regexp) do |str|
          freq[str] += 1
        end
      end
      freq
    end
  end
end
