class Article < ActiveRecord::Base
  has_many :comments
  before_move :ArticleArchive do
    comments.each { |c| c.move_to(CommentArchive) }
  end
  before_copy :ArticleArchive do
    comments.each { |c| c.copy_to(CommentArchive) }
  end
end