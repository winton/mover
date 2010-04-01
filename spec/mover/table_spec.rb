require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Mover::Base::Table do

  before(:all) do
    $db.migrate(1)
    $db.migrate(0)
    $db.migrate(1)
  end

  describe :create_movable_table do

    before(:all) do
      @article_columns = connection.columns("articles").collect(&:name)
      @archive_columns = connection.columns("articles_archive").collect(&:name)
    end

    it "should create an archive table" do
      connection.table_exists?("articles_archive").should == true
    end

    it "should create an archive table with the same structure as the original table" do
      @article_columns.each do |col|
        @archive_columns.include?(col).should == true
      end
    end
    
    describe 'with options' do
      
      before(:all) do
        Article.drop_movable_table(:archive)
        Article.create_movable_table(
          :archive,
          :columns => %w(id read),
          :indexes => %w(read)
        )
        @archive_columns = connection.columns("articles_archive").collect(&:name)
      end
      
      after(:all) do
        Article.drop_movable_table(:archive)
        Article.create_movable_table(:archive)
      end
      
      it "should create the correct columns" do
        @archive_columns.length.should == 2
        %w(id read).each do |col|
          @archive_columns.include?(col).should == true
        end
      end
      
      it "should create archive indexes" do
        indexes = Article.send(:indexed_columns, 'articles_archive')
        indexes.to_set.should == [ "read" ].to_set
      end
    end
    
    describe 'without options' do
      
      it "should create archive indexes" do
        indexes = Article.send(:indexed_columns, 'articles_archive')
        indexes.to_set.should == [ "id", "title" ].to_set
      end
    end
  end
  
  describe :drop_movable_table do
    
    it "should drop the table" do
      Article.drop_movable_table(:archive)
      output = connection.execute(<<-SQL)
        SELECT COUNT(*)
        FROM information_schema.tables 
        WHERE table_schema = '#{Article.configurations['test']['database']}' 
        AND table_name = 'articles_archive';
      SQL
      output.fetch_row.should == ['0']
    end
  end
end