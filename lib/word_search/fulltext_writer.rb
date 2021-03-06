
module WordSearch
  class FulltextWriter
    include InMemoryWriter
  
    DEFAULT_OPTIONS = {
      :path => "fulltext-#{Process.pid}-#{rand(100000)}",
    }
  
    attr_reader :path
  
    def initialize(options = {})
      options = DEFAULT_OPTIONS.merge(options)
      @path   = options[:path]
      if @path
        @io     = File.open(@path, "wb")
      else
        @io     = memory_io
      end
    end
  
    def merge(fulltext_reader)
      fulltext_reader.dump_data do |data|
        @io.write data
      end
    end
  
    def add_document(doc_id, doc_hash, field_mapping, field_infos, suffix_array_writer, doc_map_writer)
      write_document_header(doc_id, doc_hash, field_mapping, field_infos)
      doc_map_writer.add_document(doc_id, doc_hash[:uri])
      doc_hash.each_pair do |field_name, data|
        if field_id = field_mapping[field_name]
          field_info = field_infos[field_name]
          if field_info[:stored]
            suffix_offset, segment_offset = store_field(doc_id, field_name, field_id, data)
            if analyzer = field_info[:analyzer]
              suffix_array_writer.add_suffixes(analyzer, data, suffix_offset)
            end
            doc_map_writer.add_field(segment_offset, doc_id, field_id, data.size)
          end
        end
      end
    end
  
    def finish!
      @io.write "\0"
      @io.fsync
      @io.close
    end
    
    private

    # Writes the length of the document.    
    def write_document_header(doc_id, doc_hash, field_mapping, field_infos)
      stored_fields = doc_hash.select do |field_name, data|
        field_infos[field_name][:stored]
      end
      total_size = stored_fields.inject(0) {|s,(_,data)| s + data.size } + stored_fields.size * 9
      # 9 = field ids (4 bytes) plus field size (4 bytes) plus trailing \0
      @io.write [total_size].pack("V")
    end
  
    # Writes the field_id, the data length, the data, and a trailing \0
    def store_field(doc_id, field_name, field_id, data)
      @io.write [field_id, data.size].pack("V2")
      offset = @io.pos
      @io.write data
      @io.write "\0"
  
      [offset, offset - 8]
    end
  end
end

=begin

Fulltext format:

(document:
  4B: length of this document
  (field:
    4B: id
    4B: value length
    DATA: value
    \0
  )+
)+
\0

=end







