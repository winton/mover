Mover
=====

Move ActiveRecord records across tables like it ain't no thang.

Requirements
------------

<pre>
sudo gem install mover
</pre>

Defining the model
------------------

<pre>
class Article < ActiveRecord::Base
  is_movable
end
</pre>

Creating a duplicate table
--------------------------

Before moving records to another table, you must first create a table with duplicate schema.

This code is probably best suited for a migration:

<pre>
Article.to(
  :archived,
    # Name of new table will be "archived_articles"
  
  :columns => %w(id title body created_at),
    # Only create certain columns (defaults to all)
  
  :extra_columns => %w(move_id moved_at),
    # Extra columns to create
  
  :indices => %(id created_at moved_at)
    # Only create certain indices (defaults to all)
)
</pre>

The extra columns, <code>move\_id</code> and <code>moved\_at</code>, are <a href="#magic_columns">magic columns</a>.

Moving records
--------------

<pre>
article = Article.last
article.to(:archived)
</pre>

Any relationships that are movable and have a similarly named "archived" table will also be moved.

Restoring records
-----------------

<pre>
Article.from(:archived, [ "created_at > ?", Date.today ])
</pre>

<a name="magic_columns"></a>

Magic columns
-------------

By default, restoring a record will only restore itself and not its relationships (should it have had movable relationships). To restore the relationships as well, you need to specify <code>move\_id</code> as an <code>extra\_columns</code> option for all tables involved.

If you need to know when the record was moved, add <code>moved\_at</code> as an <code>extra\_columns</code> option.