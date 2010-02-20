
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
      
    def initialize(suffix_array_reader, fulltext_reader)
      @suffixes = suffix_array_reader
      @fulltext_reader = fulltext_reader
    end
      
    def count_hits(term)
      from = binary_search(term, 0, @suffixes.size)
      offset = @suffixes[from]
      if @fulltext_reader.get_data(offset, term.size) == term
        to = binary_search_upper(term, 0, @suffixes.size)
        to - from
      else
        0
      end
    end

    def find_all(term)
      from = binary_search(term, 0, @suffixes.size)
      offset = @suffixes[from]
      if @fulltext_reader.get_data(offset, term.size) == term
        to = binary_search_upper(term, 0, @suffixes.size)
        SuffixSearcher::LazyHits.new(term, self, @fulltext_reader, from, to)
      else
        SuffixSearcher::LazyHits.new(term, self, @fulltext_reader, 0, 0)
      end
    end

    def find_first(term)
      suffix_index = binary_search(term, 0, @suffixes.size)
      offset = @suffixes[suffix_index]
      if @fulltext_reader.get_data(offset, term.size) == term
        SuffixSearcher::Hit.new(term, suffix_index, offset, @fulltext_reader)
      else
        nil
      end
    end

    def binary_search(term, from, to)
      from, to = binary_search_inline_suffixes(term, from, to)
  
      tsize = term.size
      while from < to
        middle = (from + to) / 2
        pivot = @fulltext_reader.get_data(@suffixes[middle], tsize)
        if term <= pivot
          to = middle
        else
          from = middle + 1
        end
      end
  
      from
    end
  
    def binary_search_upper(term, from, to)
      from, to = binary_search_inline_suffixes_upper(term, from, to)
      
      tsize = term.size
  
      #puts "#{from} -- #{to}"
      #from.upto(to+5) do |idx|
      #  puts "#{idx}  #{@fulltext_reader.get_data(@suffixes[idx], tsize + 10).inspect}"
      #end
      while from < to
        middle = (from + to) / 2
        pivot = @fulltext_reader.get_data(@suffixes[middle], tsize)
        if term < pivot
          to = middle
        else
          from = middle + 1
        end
      end
  
      #puts "RET: #{from}"
      from
    end
  
  
    def binary_search_inline_suffixes(term, from, to)
      return [from, to] if @suffixes.block_size == 0
  
      tsize = term.size
      while to - from > @suffixes.block_size
        middle = (from + to) / 2
        #puts "from: #{from}  to #{to}  middle: #{middle}" if $DEBUG
        quotient, mod = middle.divmod(@suffixes.block_size)
        middle = middle - mod
        pivot = @suffixes.inline_suffixes[quotient]
        #puts "NOW: #{middle}  pivot: #{pivot.inspect}" if $DEBUG
        if tsize <= @suffixes.inline_suffix_size
          if term <= pivot
            to = middle
          else
            from = middle + 1
          end
        elsif term[0, @suffixes.inline_suffix_size] < pivot
          to = middle
        else
          # FIXME: handle pivot[-1] = 255?
          pivot = pivot.clone
          pivot[-1] += 1
          #puts "TESTING AGAINST new pivot: #{pivot.inspect}" if $DEBUG
          if term > pivot
            from = middle + 1
          else  # term[0, @inline_suffix_size] == pivot, disambiguate
            pivot = @fulltext_reader.get_data(@suffixes[middle], term.size)
            if term <= pivot
              to = middle
            else
              from = middle + 1
            end
          end
        end
      end
  
      [from, to]
    end
  
    def binary_search_inline_suffixes_upper(term, from, to)
      return [from, to] if @suffixes.block_size == 0
  
      tsize = term.size
      while to - from > @suffixes.block_size
        middle = (from + to) / 2
        #puts "from: #{from}  to #{to}  middle: #{middle}" if $DEBUG
        quotient, mod = middle.divmod(@suffixes.block_size)
        middle = middle - mod
        pivot = @suffixes.inline_suffixes[quotient]
        #puts "NOW: #{middle}  pivot: #{pivot.inspect}" if $DEBUG
        if tsize <= @suffixes.inline_suffix_size
          if term < pivot[0, tsize]
            to = middle
          else
            from = middle + 1
          end
        elsif term[0, @suffixes.inline_suffix_size] < pivot
          to = middle
        else
          # FIXME: handle pivot[-1] = 255?
          pivot = pivot.clone
          pivot[-1] += 1
          #puts "TESTING AGAINST new pivot: #{pivot.inspect}" if $DEBUG
          if term > pivot
            from = middle + 1
          else  # term[0, @inline_suffix_size] == pivot, disambiguate
            pivot = @fulltext_reader.get_data(@suffixes[middle], term.size)
            if term < pivot
              to = middle
            else
              from = middle + 1
            end
          end
        end
      end
  
      [from, to]
    end
  end
end