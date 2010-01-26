
begin
  require 'rubygems'
rescue LoadError
end
require 'ferret'

index = Ferret::Index::Index.new(:path => "ferret_index-linux")
until (print "Input term: "; term = $stdin.gets.chomp).empty?
  if term[0] == ?!
    limit = 1
    term = term[1..-1]
  else
    limit = :all
  end
  t0 = Time.new
  results = index.search(term, :limit => limit)
  t1 = Time.new
  #results.hits[0..100].each{|hit| index[hit.doc][:uri] }
  d1 = Time.new - t0
  results.hits.map{|hit| index[hit.doc][:uri]}
  d2 = Time.new - t1
  d3 = Time.new - t0
  puts "Needed #{d1} for the search."
  puts "Needed #{d2} to get the URIs."
  puts "Total time: #{d3}"
  puts "Total matches: #{results.total_hits}"
  puts "Showing top 10 matches:"
  puts results.hits[0..10].map{|hit| "%5.3f %s" % [hit.score, index[hit.doc][:uri]]}
end

