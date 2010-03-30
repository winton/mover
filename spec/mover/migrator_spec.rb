require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Mover::Migrator do
  
  before(:each) do
    $db.migrate(0)
    $db.migrate(1)
    Article.drop_movable_table(:archived)
    Article.create_movable_table(:archived)
  end
  
  describe :method_missing_with_mover do
    
    it 'should migrate both tables up' do
      migrate_with_state(2)
      (@new_article_columns - @old_article_columns).should == [ 'permalink' ]
      (@new_archive_columns - @old_archive_columns).should == [ 'permalink' ]
    end
    
    it 'should migrate both tables down' do
      $db.migrate(2)
      migrate_with_state(1)
      (@old_article_columns - @new_article_columns).should == [ 'permalink' ]
      (@old_archive_columns - @new_archive_columns).should == [ 'permalink' ]
    end
    
    it "should not touch the archive's move_id or moved_at column" do
      migrate_with_state(3)
      (@old_article_columns - @new_article_columns).should == [ 'move_id', 'moved_at' ]
      (@old_archive_columns - @new_archive_columns).should == []
    end
  end
end
