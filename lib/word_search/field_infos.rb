
module WordSearch
  # A class representing a set of fields.
  class FieldInfos
    def initialize(default_analyzer=nil)
      @fields           = {}
      @default_analyzer = default_analyzer
    end
    
    def default_analyzer
      @default_analyzer ||= WordSearch::Analysis::WhiteSpaceAnalyzer.new
    end
    
    def add_field(name, analyzer=nil, stored=true)
      analyzer = analyzer || default_analyzer
      @fields[name] = {:stored => stored, :analyzer => analyzer}
    end
  
    def [](field_name)
      @fields[field_name]
    end
  end
end

