
require File.dirname(__FILE__) + '/lib/word_search'

FileUtils.rm_rf "INDEX-test"

class FileNameAnalyzer < WordSearch::Analysis::Analyzer

  def append_suffixes(array, text, offset)
    sc = StringScanner.new(text)
    until sc.eos?
      array << (sc.pos + offset)
      sc.skip(%r{[^/.]*[/.]?})
    end

    array
  end
  
end

field_infos = WordSearch::FieldInfos.new
field_infos.add_field(:name => :uri, :analyzer => FileNameAnalyzer.new)
field_infos.add_field(:name => :body, :analyzer => WordSearch::Analysis::SimpleIdentifierAnalyzer.new)

fragment  = WordSearch::FragmentWriter.new(:path => "INDEX-test", :field_infos => field_infos)

file_list = Dir[ARGV[0]]

file_list[0, file_list.size/1].each do |file|
  body = File.read(file)
  puts "adding #{file} -- #{body.size}"
  fragment.add_document(:uri => file, :body => body)
end

puts "writing"
fragment.finish!
