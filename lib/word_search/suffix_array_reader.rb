
module WordSearch
  
  class SuffixArrayReader
    DEFAULT_OPTIONS = {
      :path => nil,
      :io   => nil,
    }
    
    attr_reader :block_size
    
    def initialize(doc_map, options = {})
      options = DEFAULT_OPTIONS.merge(options)
      @doc_map         = doc_map
      unless options[:path] || options[:io]
        raise ArgumentError, "Need either the path to the suffix array file or an IO."
      end
      init_internal_structures(options)
    end
    
    def suffix_index_to_offset(suffix_index)
      @suffixes[suffix_index]
    end
  
    def lazyhits_to_offsets(lazyhits)
      from = lazyhits.from_index
      to   = lazyhits.to_index
      @io.pos = @base + 4 * from
      @io.read((to - from) * 4).unpack("V*")
    end
  
    def dump_data
      @io.pos = @base
      while data = @io.read(32768)
        yield data.unpack("V*")
      end
    end
  
    def size
      @suffixes.size
    end
    
    def [](ix)
      @suffixes[ix]
    end
  
    private
    
    def init_internal_structures(options)
      if options[:path]
        @io = File.open(options[:path], "rb")
      else
        @io = options[:io]
      end
      @total_suffixes, @block_size, @inline_suffix_size = @io.read(12).unpack("VVV")
      @inline_suffixes = []
      if @block_size != 0
        0.step(@total_suffixes, @block_size){ @inline_suffixes << @io.read(@inline_suffix_size)}
      end
  
      # skip padding
      if (mod = @io.pos & 0xf) != 0
        @io.read(16 - mod)
      end
  
      @base = @io.pos
      #@suffixes = io.read.unpack("V*")
      @suffixes = Object.new
      nsuffixes = @total_suffixes
      io = @io
      base = @base
      class << @suffixes; self end.module_eval do 
        define_method(:[]) do |i|
          io.pos = base + i * 4
          io.read(4).unpack("V")[0]
        end
        define_method(:size){ nsuffixes }
      end
    end
  end
end
