
module WordSearch
  class FieldInfos
    DEFAULT_OPTIONS = {
      :stored => true,
    }

    attr_writer :default_analyzer
    
    def initialize(options = {})
      options = DEFAULT_OPTIONS.merge(options)
      @fields = {}
      @default_options = options
    end
    
    def default_analyzer
      @default_analyzer ||= WordSearch::Analysis::WhiteSpaceAnalyzer.new
    end
    
    def add_field(options = {})
      options = @default_options.merge(options)
      raise "Need a name" unless options[:name]
      store_field_info(options)
    end
  
    def [](field_name)
      if field_info = @fields[field_name]
        field_info
      else
        store_field_info(:name => field_name)
      end
    end
  
    private
    
    def store_field_info(options)
      options = @default_options.merge(options)
      unless options[:analyzer]
        if klass = options[:analyzer_class]
          options[:analyzer] = klass.new
        else
          options[:analyzer] = default_analyzer
        end
      end
      @fields[options[:name]] = options
    end
  end
end

