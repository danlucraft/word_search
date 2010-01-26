
require File.dirname(__FILE__) + '/lib/word_search'

BASE_PATH="INDEX_incremental"

field_infos = WordSearch::FieldInfos.new
field_infos.add_field(:name => :uri, :analyzer => WordSearch::Analysis::SimpleIdentifierAnalyzer.new)
field_infos.add_field(:name => :body, :analyzer => WordSearch::Analysis::WhiteSpaceAnalyzer.new)

latest = Dir["#{BASE_PATH}-*"].sort.last

if latest
  fragment  = WordSearch::FragmentWriter.new(:path => latest.succ, :field_infos => field_infos)
  fragment.merge(latest)
else
  fragment  = WordSearch::FragmentWriter.new(:path => "#{BASE_PATH}-0000000", 
                                           :field_infos => field_infos)
end

ARGV.each do |fname|
  fragment.add_document(:uri => fname, :body => File.read(fname))
end

fragment.finish!

require 'fileutils'
FileUtils.rm_r(latest) if latest
