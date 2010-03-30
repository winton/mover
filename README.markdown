Mover
=====

Move ActiveRecord records across tables like it ain't no thang.

Requirements
------------

<pre>
sudo gem install mover
</pre>

Create the duplicate table
--------------------------

<pre>
class CreateArchivedArticles < ActiveRecord::Migration
  def self.up
    Article.create_movable_table(
      # Table will be named "archived_articles"
      :archived,

      # Only create certain columns (defaults to all)
      :columns => %w(id title body created_at),

      # Extra columns to create
      :extra_columns => { :move_id => :integer, :moved_at => :datetime },

      # Only create certain indexes (defaults to all)
      :indexes => %(id created_at moved_at)
    )
  end

  def self.down
    Article.drop_movable_table(:archived)
  end
end
</pre>

The extra columns, <code>move\_id</code> and <code>moved\_at</code>, are <a href="#magic_columns">magic columns</a>.

Defining the model
------------------

<pre>
class Article < ActiveRecord::Base
  is_movable :archived
end
</pre>

Moving records
--------------

<pre>
article = Article.last
article.move_to(:archived)
</pre>

To automatically move a record's relationships, each relationship will need a movable <code>:archived</code> table and an <code>is_movable :archived</code> call in the model.

Restoring records
-----------------

<pre>
Article.move_from(:archived, [ "created_at > ?", Date.today ])
</pre>

<a name="magic_columns"></a>

Magic columns
-------------

By default, restoring a record will only restore itself and not its relationships. To restore the relationships as well, you need to specify <code>move\_id</code> as an <code>extra\_columns</code> option for all movable tables involved.

If you need to know when the record was moved, add <code>moved\_at</code> as an <code>extra\_columns</code> option.