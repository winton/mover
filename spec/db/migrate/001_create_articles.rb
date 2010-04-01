class CreateArticles < ActiveRecord::Migration
  def self.up
    create_table :articles do |t|
      t.string :title
      t.string :body
      t.boolean :read
    end
    add_index :articles, :title
    
    Article.create_movable_table(:archive)
    add_column :articles_archive, :move_id, :string
    add_column :articles_archive, :moved_at, :datetime
    
    Article.create_movable_table(:draft)
    
    create_table :comments do |t|
      t.string :title
      t.string :body
      t.boolean :read
      t.integer :article_id
    end
    
    Comment.create_movable_table(:archive)
    add_column :comments_archive, :move_id, :string
    add_column :comments_archive, :moved_at, :datetime
  end

  def self.down
    drop_table :articles
    drop_table :comments
    Article.drop_movable_table(:archive)
    Comment.drop_movable_table(:archive)
  end
end
