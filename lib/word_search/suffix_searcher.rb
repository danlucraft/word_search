
module WordSearch
  class SuffixSearcher
    class Hit < Struct.new(:term, :suffix_number, :offset, :fulltext_reader)
      def context(size)
        strip_markers(self.fulltext_reader.get_data(offset - size, 2 * size), size)
      end
  
      def text(size)
        strip_markers(self.fulltext_reader.get_data(offset, size), 0)
      end
  
      private
      def strip_markers(str, size)
        first = (str.rindex("\0", -size) || -1) + 1
        last  = str.index("\0", size) || str.size
        str[first...last]
      end
    end
  
    class LazyHits < Struct.new(:term, :suffix_array_reader, :fulltext_reader, 
                                :from_index, :to_index)
      include Enumerable
      def each
        sa_reader = self.suffix_array_reader
        ft_reader = self.fulltext_reader
        term      = self.term
        self.from_index.upto(self.to_index - 1) do |idx|
          yield Hit.new(term, idx, sa_reader.suffix_index_to_offset(idx), 
                        ft_reader)
        end
      end
  
      def [](i)
        i += to_index - from_index if i < 0
        sa_reader = self.suffix_array_reader
        if (idx = from_index + i) < to_index && idx >= from_index
          Hit.new(self.term, idx, sa_reader.suffix_index_to_offset(idx),
                  self.fulltext_reader)
        else
          nil
        end
      end
  
      def size
        to_index - from_index
      end
    end
  end
end