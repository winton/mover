class CreateFixtures < ActiveRecord::Migration
  def self.up
    [ :articles, :article_archives ].each do |table|
      create_table table do |t|
        t.string :title
        t.string :body
        t.boolean :read
        t.datetime :moved_at
      end
    end
    
    [ :comments, :comment_archives ].each do |table|
      create_table table do |t|
        t.string :title
        t.string :body
        t.boolean :read
        t.integer :article_id
        t.datetime :moved_at
      end
    end
  end

  def self.down
    [ :articles, :article_archives, :comments, :comment_archives ].each do |table|
      drop_table table
    end
  end
end