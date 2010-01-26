
module WordSearch
  module Analysis
  
  class Analyzer
    def find_suffixes(text)
      ret = []
      append_suffixes(ret, text, 0)
      ret
    end
  end
  
  end
end
