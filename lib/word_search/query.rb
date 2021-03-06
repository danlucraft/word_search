
module WordSearch
  class Query
    attr_reader :dir, :probabilistic_sorting
    attr_writer :fulltext_reader
  
    def initialize(dir, probabilistic_sorting)
      @dir = dir
      @probabilistic_sorting = probabilistic_sorting
    end
    
    def fulltext_reader
      @fulltext_reader ||= WordSearch::FulltextReader.new(:path => "#{dir}/fulltext")
    end
    
    def suffix_array_reader
      @suffix_array_reader ||= WordSearch::SuffixArrayReader.new(nil, :path => "#{dir}/suffixes")
    end
    
    def doc_map_reader
      @doc_map_reader ||= WordSearch::DocumentMapReader.new(:path => "#{dir}/docmap")
    end
    
    def search_a(line)
      line = line[1..-1]
      t = Time.new
      searcher = WordSearch::SuffixSearcher.new(suffix_array_reader, fulltext_reader)
      until hit = searcher.find_first(line)
		    puts "Needed #{Time.new - t}"
		  end
      t = Time.new
      puts "Total hits: #{searcher.count_hits(line)} (#{Time.new - t})"
    end
  
    def search_b(line)
      h = Hash.new{|h,k| h[k] = 0}
      weights = Hash.new(1.0)
      weights[0] = 10000000  # :uri
      weights[1] = 10000000  # :body
      t0 = Time.new
      searcher = WordSearch::SuffixSearcher.new(suffix_array_reader, fulltext_reader)
      hits = searcher.find_all(line)
      d1 = Time.new - t0
      t1 = Time.new
      size = hits.size
      if probabilistic_sorting && size > 10000
        iterations = 50 * Math.sqrt(size)
        offsets = suffix_array_reader.lazyhits_to_offsets(hits)
        weight_arr = weights.sort_by{|id,w| id}.map{|_,v| v}
        sorted = doc_map_reader.rank_offsets_probabilistic(offsets, weight_arr,
                                                           iterations)
      else
        offsets = suffix_array_reader.lazyhits_to_offsets(hits)
        sorted = doc_map_reader.rank_offsets(offsets, weights.sort_by{|id,w| id}.map{|_,v| v})
        d1 
      end
      d2 = Time.new - t1
      #sorted[0..100].each{|doc_id, score| doc_map_reader.document_id_to_uri(doc_id)}
      t2 = Time.new
      sorted.each {|doc_id, score| doc_map_reader.document_id_to_uri(doc_id) }
      d3 = Time.new - t2
      d4 = Time.new - t0
      puts "Needed #{d1} for the search."
      puts "Needed #{d2} to rank #{hits.size} hits into #{sorted.size} docs"
      puts "Needed #{d3} to get the URIs."
      puts "Total time: #{d4}"
      puts "Showing top 10 matches:"
      puts sorted[0..10].map{ |doc_id, count|
        "%6d %5d %s" % [count, doc_id, doc_map_reader.document_id_to_uri(doc_id)]
      }
    end
  end
end
