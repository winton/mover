require 'spec_helper'

describe Mover do
  
  describe :copy do
  
    before(:each) do
      [ 1, 0, 1 ].each { |v| $db.migrate(v) }
      @articles = create_records(Article)
      @comments = create_records(Comment)
      @articles[0].move_to(ArticleArchive, :copy => true)
    end
  
    describe 'should copy both articles and their associations' do
      it "should copy articles" do
        Article.move_to(
          ArticleArchive,
          :conditions => [ 'articles.id = ? OR articles.id = ? OR articles.id = ?', 1, 2, 3 ],
          :copy => true
        )
        Article.count.should == 5
        Comment.count.should == 5
        ArticleArchive.count.should == 3
        CommentArchive.count.should == 3
      end
    end
  
    describe 'should overwrite first copy if copied twice' do
      it "should copy articles" do
        Article.find(1).update_attributes(:title => 'foobar edited')
        Article.move_to(
          ArticleArchive,
          :conditions => [ 'articles.id = ? OR articles.id = ? OR articles.id = ?', 1, 2, 3 ],
          :copy => true
        )
        ArticleArchive.find(1).title.should == 'foobar edited'
        Article.count.should == 5
        Comment.count.should == 5
        ArticleArchive.count.should == 3
        CommentArchive.count.should == 3
      end
    end
  end
  
  describe :move do
  
    before(:each) do
      [ 1, 0, 1 ].each { |v| $db.migrate(v) }
      @articles = create_records(Article)
      @comments = create_records(Comment)
      @articles[0].move_to(ArticleArchive)
      Article.move_to(
        ArticleArchive,
        :conditions => [ 'articles.id = ?', 2 ]
      )
    end
  
    describe 'move records' do
  
      it "should move both articles and their associations" do
        Article.count.should == 3
        Comment.count.should == 3
        ArticleArchive.count.should == 2
        CommentArchive.count.should == 2
        Article.find_by_id(1).nil?.should == true
        Comment.find_by_id(2).nil?.should == true
        ArticleArchive.find_by_id(1).nil?.should == false
        CommentArchive.find_by_id(2).nil?.should == false
        comments = ArticleArchive.find_by_id(1).comments
        comments.length.should == 1
        comments.first.id.should == 1
        comments = ArticleArchive.find_by_id(2).comments
        comments.length.should == 1
        comments.first.id.should == 2
      end
  
      it "should assign moved_at" do
        ArticleArchive.find_by_id(1).moved_at.utc.to_s.should == Time.now.utc.to_s
      end
    end
  
    describe 'move records back' do
  
      before(:each) do
        ArticleArchive.find(1).move_to(Article)
        ArticleArchive.move_to(
          Article,
          :conditions => [ 'article_archives.id = ?', 2 ]
        )
      end
  
      it "should move both articles and their associations" do
        Article.count.should == 5
        Comment.count.should == 5
        ArticleArchive.count.should == 0
        CommentArchive.count.should == 0
        Article.find_by_id(1).nil?.should == false
        Comment.find_by_id(2).nil?.should == false
        ArticleArchive.find_by_id(1).nil?.should == true
        CommentArchive.find_by_id(2).nil?.should == true
        comments = Article.find_by_id(1).comments
        comments.length.should == 1
        comments.first.id.should == 1
        comments = Article.find_by_id(2).comments
        comments.length.should == 1
        comments.first.id.should == 2
      end
    end
  end
  
  describe :reserve_id do
    it "should return an id" do
      Article.reserve_id.class.should == Fixnum
    end
  
    it "should delete the record" do
      id = Article.reserve_id
      Article.find_by_id(id).should == nil
    end
  end
end