class CreateArticles < ActiveRecord::Migration
  def self.up
    create_table :articles do |t|
      t.string :title
      t.string :body
      t.boolean :read
    end
    add_index :articles, :title
    
    Article.create_movable_table(:archived)
    add_column :archived_articles, :move_id, :string
    add_column :archived_articles, :moved_at, :datetime
    
    Article.create_movable_table(:drafted)
    
    create_table :comments do |t|
      t.string :title
      t.string :body
      t.boolean :read
      t.integer :article_id
    end
    
    Comment.create_movable_table(:archived)
    add_column :archived_comments, :move_id, :string
    add_column :archived_comments, :moved_at, :datetime
  end

  def self.down
    drop_table :articles
    drop_table :comments
    Article.drop_movable_table(:archived)
    Comment.drop_movable_table(:archived)
  end
end
