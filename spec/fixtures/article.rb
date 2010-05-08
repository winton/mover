class Article < ActiveRecord::Base
  has_many :comments
  before_move :ArticleArchive do
    comments.each { |c| c.move_to(CommentArchive, move_options) }
  end
end