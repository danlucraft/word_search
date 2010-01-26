
module WordSearch
  module InMemoryWriter
    def initialize_in_memory_buffer
      @memory_io = StringIO.new("")
    end
  
    def data
      if @path
        File.open(@path, "rb"){|f| f.read} rescue nil
      else
        @memory_io.string.clone
      end
    end
  end
end
