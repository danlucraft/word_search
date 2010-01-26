$:.unshift File.dirname(__FILE__)

require 'stringio'
require 'enumerator'
require 'fileutils'
require 'strscan'

require 'word_search/analysis/analyzer'
require 'word_search/analysis/simple_identifier_analyzer'
require 'word_search/analysis/whitespace_analyzer'

require 'word_search/in_memory_writer'
require 'word_search/document_map_reader'
require 'word_search/document_map_writer'
require 'word_search/field_infos'
require 'word_search/fulltext_reader'
require 'word_search/fulltext_writer'
require 'word_search/suffix_array_reader'
require 'word_search/suffix_array_writer'

require 'word_search/fragment_writer'
 