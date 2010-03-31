require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Mover::Base::Table do

  before(:all) do
    $db.migrate(0)
    $db.migrate(1)
    Article.drop_movable_table(:archived)
    Article.create_movable_table(:archived)
  end

  describe :create_movable_table do

    before(:all) do
      @article_columns = connection.columns("articles").collect(&:name)
      @archive_columns = connection.columns("archived_articles").collect(&:name)
    end

    it "should create an archive table" do
      connection.table_exists?("archived_articles").should == true
    end

    it "should create an archive table with the same structure as the original table" do
      @article_columns.each do |col|
        @archive_columns.include?(col).should == true
      end
    end
    
    describe 'with options' do
      
      before(:all) do
        Article.drop_movable_table(:archived)
        Article.create_movable_table(
          :archived,
          :columns => %w(id read),
          :indexes => %w(read)
        )
        @archive_columns = connection.columns("archived_articles").collect(&:name)
      end
      
      after(:all) do
        Article.drop_movable_table(:archived)
        Article.create_movable_table(:archived)
      end
      
      it "should create the correct columns" do
        @archive_columns.length.should == 2
        %w(id read).each do |col|
          @archive_columns.include?(col).should == true
        end
      end
      
      it "should create archive indexes" do
        indexes = Article.send(:indexed_columns, 'archived_articles')
        indexes.to_set.should == [ "read" ].to_set
      end
    end
    
    describe 'without options' do
      
      it "should create archive indexes" do
        indexes = Article.send(:indexed_columns, 'archived_articles')
        indexes.to_set.should == [ "id", "title" ].to_set
      end
    end
  end
  
  describe :drop_movable_table do
    
    it "should drop the table" do
      Article.drop_movable_table(:archived)
      output = connection.execute(<<-SQL)
        SELECT COUNT(*)
        FROM information_schema.tables 
        WHERE table_schema = '#{Article.configurations['test']['database']}' 
        AND table_name = 'archived_articles';
      SQL
      output.fetch_row.should == ['0']
    end
  end
end