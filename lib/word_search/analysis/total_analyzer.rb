
module WordSearch
  module Analysis
    class TotalAnalyzer < Analyzer
      def append_suffixes(array, text, offset)
      
        sc = StringScanner.new(text)
        sc.skip(/[^A-Za-z_]+/)
        until sc.eos?
          array << (sc.pos + offset)
          break unless sc.skip(/./m)
        end
      end
    end
  end
end
 