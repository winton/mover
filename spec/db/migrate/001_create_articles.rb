class CreateArticles < ActiveRecord::Migration
  def self.up
    create_table :articles do |t|
      t.string :title
      t.string :body
      t.boolean :read
      t.integer :move_id
      t.datetime :moved_at
    end
    add_index :articles, :title
  end

  def self.down
    drop_table :articles
  end
end
