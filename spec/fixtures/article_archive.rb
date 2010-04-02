class ArticleArchive < ActiveRecord::Base
  has_many :comments, :class_name => 'CommentArchive', :foreign_key => 'article_id'
  before_move_to :Article do
    comments.each { |c| c.move_to(Comment) }
  end
end