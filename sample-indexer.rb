# Copyright (C) 2006  Mauricio Fernandez <mfp@acm.org>
#
$:.unshift "lib"
$:.unshift "ext/ftsearch"

require 'ftsearch/fragment_writer'
require 'ftsearch/field_infos'
require 'ftsearch/analysis/simple_identifier_analyzer'

require 'ftsearchrt'

require 'fileutils'
FileUtils.rm_rf "INDEX-test"

require 'strscan'
class FileNameAnalyzer < FTSearch::Analysis::Analyzer
  def append_suffixes(array, text, offset)
    sc = StringScanner.new(text)
    until sc.eos?
      array << (sc.pos + offset)
      sc.skip(%r{[^/.]*[/.]?})
    end

    array
  end
end

field_infos = FTSearch::FieldInfos.new
field_infos.add_field(:name => :uri, :analyzer => FileNameAnalyzer.new)
field_infos.add_field(:name => :body, :analyzer => FTSearch::Analysis::SimpleIdentifierAnalyzer.new)

fragment  = FTSearch::FragmentWriter.new(:path => "INDEX-test", :field_infos => field_infos)
reuters = Dir["corpus/reuters/**/*.txt"]
linux = Dir["corpus/linux/**/*.{c,h}"]
case ARGV[0]
when "reuters"; file_list = reuters
when "linux"  ; file_list = linux
else
  file_list = reuters
end
file_list[0, file_list.size/1].each do |file| 
  body = File.read(file)
  #puts "adding #{file} -- #{body.size}"
  fragment.add_document(:uri => file, :body => body)
end
puts "writing"
fragment.finish!
