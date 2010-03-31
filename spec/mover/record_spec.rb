require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Mover::Base::Record do
  
  before(:all) do
    $db.migrate(0)
    $db.migrate(1)
    Article.drop_movable_table(:archived)
    Article.create_movable_table(:archived)
  end
  
  describe :move_to do
  
    before(:all) do
      @articles = create_records
      Article.find(@articles[0..1].collect(&:id)).each do |a|
        a.move_to(:archived)
      end
    end
  
    it "should move some records to the archive table" do
      Article.count.should == 3
      ArchivedArticle.count.should == 2
    end
  
    it "should preserve record attributes" do
      2.times do |x|
        original = @articles[x]
        copy = ArchivedArticle.find(original.id)
        article_match?(original, copy)
      end
    end
  end
end
