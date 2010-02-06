
module WordSearch

  class FragmentWriter
    DEFAULT_PATH = "wordsearch-#{Process.pid}-#{rand(100000)}"
    
    attr_reader :path, :num_documents
    attr_writer :default_analyzer, :field_infos, :field_map, :fulltext_writer, :doc_map_writer, :suffix_array_writer
  
    def initialize(path)
      @path = path || DEFAULT_PATH
      FileUtils.mkdir_p(tmpdir)
      @num_documents = 0
    end
    
    def build_path(suffix)
      path ? File.join(tmpdir, suffix) : nil
    end
    
    def tmpdir
      @tmpdir ||= path + "#{Process.pid}-#{rand(100000)}"
    end
    
    def path
      File.expand_path(@path)
    end
    
    def default_analyzer
      @default_analyzer ||= WordSearch::Analysis::WhiteSpaceAnalyzer.new
    end
    
    def field_infos
      @field_infos ||= begin
        fis = FieldInfos.new
        fis.default_analyzer = default_analyzer
        fis
      end
    end
    
    def field_map
      @field_map ||= begin
        r = Hash.new{|h,k| h[k.to_sym] = h.size}
        r[:uri] # init
        r
      end
    end
    
    def fulltext_writer
      @fulltext_writer ||= FulltextWriter.new(:path => build_path("fulltext"))
    end
    
    def suffix_array_writer
      @suffix_array_writer ||= SuffixArrayWriter.new(:path => build_path("suffixes"))
    end
    
    def doc_map_writer
      @doc_map_writer ||= DocumentMapWriter.new(:path => build_path("docmap"))
    end
    
    def add_document(doc_hash)
      uri = doc_hash[:uri] || @num_documents.to_s
      fulltext_writer.add_document(
          num_documents, doc_hash.merge(:uri => uri), field_map, field_infos, suffix_array_writer, doc_map_writer
        )
      @num_documents += 1
    end
    
    def fields
      field_map.sort_by {|field, fid| fid }.map {|field, fid| field }
    end
  
    def field_id(field)
      field_map.has_key?(field) and field_map[field]
    end
  
    def finish!
      puts "#{@num_documents} docs"
      fulltext_writer.finish!
      fulltext = fulltext_writer.data
      suffix_array_writer.finish!(fulltext)
      doc_map_writer.finish!
  
      if path
        File.open(File.join(tmpdir, "fieldmap"), "wb") do |f|
          field_map.sort_by{|field_name, field_id| field_id}.each do |field_name, field_id| 
            f.puts field_name
          end
          File.rename(tmpdir, path)
        end
      end
    end
    
    def merge(fragment_directory)
      raise "Cannot import old data unless the destination Fragment is empty." unless @num_documents == 0
      # TODO: use a FragmentReader to access old data
      fulltext_reader     = FulltextReader.new(:path => "#{fragment_directory}/fulltext")
      suffix_array_reader = SuffixArrayReader.new(fulltext_reader, nil, 
                                                  :path => "#{fragment_directory}/suffixes")
      doc_map_reader      = DocumentMapReader.new(:path => "#{fragment_directory}/docmap")
      fulltext_writer.merge(fulltext_reader)
      suffix_array_writer.merge(suffix_array_reader)
      doc_map_writer.merge(doc_map_reader)
      #FIXME: .num_documents will be wrong if some URIs were repeated
      @num_documents = doc_map_reader.num_documents
      File.open(File.join(fragment_directory, "fieldmap"), "rb") do |f|
        i = 0
        f.each_line{|l| field_map[l.chomp.to_sym] = i; i+= 1}
      end
    end
  
  end
end
