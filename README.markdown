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

Move the last article to the <code>article_archives</code> table:

<pre>
Article.last.move_to(ArticleArchive)
</pre>

Move today's articles to the <code>article_archives</code> table:

<pre>
Article.move_to(
  ArticleArchive,
  :conditions => [ "created_at > ?", Date.today ]
)
</pre>

The two tables do not have to be identical. Only shared columns transfer.

If a record with the same primary key already exists, an update occurs.

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

The <code>after\_move</code> callback is also available.

Magic column
------------

If a table contains a <code>moved_at</code> column, it will magically populate with the date and time it was moved.

Options
-------

There are other options, in addition to <code>conditions</code>:

<pre>
Article.move_to(
  ArticleArchive,
  :copy => true,          # Do not delete Article after move
  :generic => true,       # UPDATE using a JOIN instead of ON DUPLICATE KEY UPDATE (slower on MySQL)
  :magic => 'updated_at', # Custom magic column
  :quick => true          # You are certain only INSERTs are necessary, no UPDATEs
)
</pre>

You can access these options from callbacks using <code>move_options</code>.

Reserve a spot
--------------

Before you create a record, you can "reserve a spot" on a table that you will move the record to later.

<pre>
archive = ArticleArchive.new
archive.id = Article.reserve_id
archive.save
</pre>