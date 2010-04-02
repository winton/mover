class CommentArchive < ActiveRecord::Base
  belongs_to :article, :class_name => 'ArticleArchive', :foreign_key => 'article_id'
end