
module WordSearch
  module Analysis
    class WhiteSpaceAnalyzer < Analyzer
      def append_suffixes(array, text, offset)
        sc = StringScanner.new(text)
        sc.skip(/(\s|\n)*/)
        until sc.eos?
          array << (sc.pos + offset)
          break unless sc.skip(/\S+\s*/)
        end
  
        array
      end
    end
  end
end
