
require File.dirname(__FILE__) + '/lib/word_search'

include WordSearch

dir = ARGV[0] || "INDEX-test"

fulltext_reader     = FulltextReader.new(:path => "#{dir}/fulltext")
suffix_array_reader = SuffixArrayReader.new(fulltext_reader, nil, :path => "#{dir}/suffixes")
doc_map_reader      = DocumentMapReader.new(:path => "#{dir}/docmap")

probabilistic_sorting = ((ARGV.last||"").index("pro"))

until (print "Input term: "; line = $stdin.gets.chomp).empty?
  if line[0] == ?!
    line = line[1..-1]
    t = Time.new
    hit = suffix_array_reader.find_first(line)
    puts "Needed #{Time.new - t}"
    p hit
    next unless hit
    p hit.context(30)
    t = Time.new
    puts "Total hits: #{suffix_array_reader.count_hits(line)} (#{Time.new - t})"
  else
    h = Hash.new{|h,k| h[k] = 0}
    weights = Hash.new(1.0)
    weights[0] = 10000000   # :uri
    weights[1] = 10000000  # :body
    t0 = Time.new
    hits = suffix_array_reader.find_all(line)
    d1 = Time.new - t0
    t1 = Time.new
    size = hits.size
    if probabilistic_sorting && size > 10000
      iterations = 50 * Math.sqrt(size)
=begin
      iterations.times do 
        idx = rand(size)
        hit = hits[idx]
        #url = doc_map_reader.document_uri(hit.suffix_number, hit.offset)
        #h[url] += 1.0 / doc_map_reader.field_size(hit.suffix_number, hit.offset)
        offset, doc_id, field_id, field_size = doc_map_reader.field_info(hit.suffix_number, hit.offset)
        h[doc_id] += weights[field_id] / field_size
      end
=end
      offsets = suffix_array_reader.lazyhits_to_offsets(hits)
      weight_arr = weights.sort_by{|id,w| id}.map{|_,v| v}
      sorted = doc_map_reader.rank_offsets_probabilistic(offsets, weight_arr,
                                                         iterations)
    else
=begin
      hits.each do |hit|
        #doc_id = doc_map_reader.document_id(hit.suffix_number, hit.offset)
        offset, doc_id, field_id, field_size = doc_map_reader.field_info(hit.suffix_number, hit.offset)
        x = weights[field_id] / field_size
        #puts "#{doc_id} #{field_id} #{weights[field_id]} #{field_size} #{hit.text(20).inspect} #{x}"
        h[doc_id] += x
      end
=end
      offsets = suffix_array_reader.lazyhits_to_offsets(hits)
      sorted = doc_map_reader.rank_offsets(offsets, weights.sort_by{|id,w| id}.map{|_,v| v})
      d1 
    end
    d2 = Time.new - t1
    #sorted[0..100].each{|doc_id, score| doc_map_reader.document_id_to_uri(doc_id)}
    t2 = Time.new
    sorted.each{|doc_id, score| doc_map_reader.document_id_to_uri(doc_id)}
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

