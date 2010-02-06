

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
 