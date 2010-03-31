class CreateArticles < ActiveRecord::Migration
  def self.up
    create_table :articles do |t|
      t.string :title
      t.string :body
      t.boolean :read
    end
    add_index :articles, :title
  end

  def self.down
    drop_table :articles
  end
end
