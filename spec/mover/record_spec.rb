require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Mover::Base::Record do
  
  before(:all) do
    $db.migrate(0)
    $db.migrate(1)
  end
  
  describe :InstanceMethods do
    describe :move_to do
  
      before(:all) do
        @articles = create_records
        @comments = create_records(Comment)
        @articles[0..1].each do |a|
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
          record_match?(original, copy)
        end
      end
    
      it "should move associated records" do
        Comment.count.should == 3
        ArchivedComment.count.should == 2
      end
    
      it "should preserve associated record attributes" do
        2.times do |x|
          original = @comments[x]
          copy = ArchivedComment.find(original.id)
          record_match?(original, copy)
        end
      end
    
      it "should populate move_id" do
        (1..2).each do |x|
          article = ArchivedArticle.find(x)
          comment = ArchivedComment.find(x)
          comment.move_id.nil?.should == false
          comment.move_id.length.should == 32
          comment.move_id.should == article.move_id
        end
      end
    
      it "should populate moved_at" do
        (1..2).each do |x|
          article = ArchivedArticle.find(x)
          comment = ArchivedComment.find(x)
          comment.moved_at.nil?.should == false
          comment.moved_at.should == article.moved_at
        end
      end
    end
  
    describe :move_from do
    
      before(:all) do
        articles = create_records
        create_records(Comment)
        articles[0..1].each do |a|
          a.move_to(:archived)
        end
        @articles = ArchivedArticle.find(1, 2)
        @comments = ArchivedComment.find(1, 2)
        @articles.each do |article|
          article.move_from
        end
      end
    
      it "should move records back to the original table" do
        Article.count.should == 5
        ArchivedArticle.count.should == 0
      end
  
      it "should preserve record attributes" do
        2.times do |x|
          original = @articles[x]
          copy = Article.find(original.id)
          record_match?(original, copy)
        end
      end
    
      it "should move associated records" do
        Comment.count.should == 5
        ArchivedComment.count.should == 0
      end
    
      it "should preserve associated record attributes" do
        2.times do |x|
          original = @comments[x]
          copy = Comment.find(original.id)
          record_match?(original, copy)
        end
      end
    end
  end
end
