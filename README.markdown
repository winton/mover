Mover
=====

Move ActiveRecord records across tables like it ain't no thang.

Requirements
------------

<pre>
sudo gem install mover
</pre>

Move records
------------

<pre>
Article.last.move_to(ArticleArchive)
Article.move_to(ArticleArchive, [ "created_at > ?", Date.today ])
</pre>

The <code>move_to</code> method is available to all models.

The two tables do not have to be identical. Only shared columns transfer.

Callbacks
---------

In this example, we want an "archive" table for articles and comments.

We also want the article's comments to be archived when the article is.

<pre>
class Article < ActiveRecord::Base
  has_many :comments
  before_move :ArticleArchive do
    comments.each { |c| c.move_to(CommentArchive) }
  end
end

class ArticleArchive < ActiveRecord::Base
  has_many :comments, :class_name => 'CommentArchive', :foreign_key => 'article_id'
  before_move :Article do
    comments.each { |c| c.move_to(Comment) }
  end
end

class Comment < ActiveRecord::Base
  belongs_to :article
end

class CommentArchive < ActiveRecord::Base
  belongs_to :article, :class_name => 'ArticleArchive', :foreign_key => 'article_id'
end
</pre>

Reserve a spot
--------------

Before you create a record, you can "reserve a spot" on a table that you will move the record to later.

<pre>
ArticleArchive.create(:id => Article.reserve_id)
</pre>

Magic columns
-------------

### moved_at

If a table contains the column <code>moved_at</code>, it will automatically be populated with the date and time it was moved.