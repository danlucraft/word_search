require 'spec_helper'

describe WordSearch::FieldInfos do
  it "should let you add a field with a name" do
    fis = WordSearch::FieldInfos.new
    fis.add_field(:body)
    fis[:body].should_not be_nil
  end
  
  it "should have a default analyzer" do
    fis = WordSearch::FieldInfos.new
    fis.add_field(:body)
    fis[:body][:analyzer].should be_an_instance_of(WordSearch::Analysis::WhiteSpaceAnalyzer)
  end
  
  it "should let you set an analyzer" do
    fis = WordSearch::FieldInfos.new
    fis.add_field(:body, :my_analyzer)
    fis[:body][:analyzer].should == :my_analyzer
  end

  it "should let you set a default analyzer" do
    fis = WordSearch::FieldInfos.new(:my_default_analyzer)
    fis.add_field(:body)
    fis[:body][:analyzer].should == :my_default_analyzer
  end

  it "should store fields by default" do
    fis = WordSearch::FieldInfos.new
    fis.add_field(:body)
    fis[:body][:stored].should be_true
  end
  
  it "should let you set that the field should not be stored" do
    fis = WordSearch::FieldInfos.new
    fis.add_field(:body, nil, false)
    fis[:body][:stored].should be_false
  end
end