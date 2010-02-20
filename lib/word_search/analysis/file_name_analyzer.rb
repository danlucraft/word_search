

class FileNameAnalyzer < WordSearch::Analysis::Analyzer

  def append_suffixes(array, text, offset)
    sc = StringScanner.new(text)
    until sc.eos?
      p [:adding_suffix, sc.pos, offset, text[(sc.pos)..-1]]
      array << sc.pos + offset
      sc.skip(%r{[^/.]*[/.]?})
    end

    array
  end
end
 