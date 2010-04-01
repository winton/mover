Mover
=====

Move ActiveRecord records across tables like it ain't no thang.

Requirements
------------

<pre>
sudo gem install mover
</pre>

<a name="create_the_movable_table"></a>

Create the movable table
------------------------

Migration:

<pre>
class CreateArticlesArchive < ActiveRecord::Migration
  def self.up
    Article.create_movable_table(
      :archive,
      :columns => %w(id title body created_at),
      :indexes => %w(id created_at)
    )
    add_column :articles_archive, :move_id, :string
    add_column :articles_archive, :moved_at, :datetime
  end

  def self.down
    Article.drop_movable_table(:archive)
  end
end
</pre>

The first parameter names your movable table. In this example, the table is named <code>articles_archive</code>.

Options:

* <code>:columns</code> - Only use certain columns from the original table. Defaults to all.
* <code>:indexes</code> - Only create certain indexes. Defaults to all.

We also added two columns, <code>move\_id</code> and <code>moved\_at</code>. These are <a href="#magic_columns">magic columns</a>.

<a name="define_the_model"></a>

Define the model
----------------

<pre>
class Article < ActiveRecord::Base
  is_movable :archive
end
</pre>

The <code>is_movable</code> method takes any number of parameters for multiple movable tables.

Moving records
--------------

<pre>
Article.last.move_to(:archive)
Article.move_to(:archive, [ "created_at > ?", Date.today ])
</pre>

Associations move if they are movable and if all movable tables have a <code>move_id</code> column (see <a href="#magic_columns">magic columns</a>).

Restoring records
-----------------

<pre>
Article.move_from(:archive, [ "created_at > ?", Date.today ])
ArticleArchive.last.move_from
</pre>

You can access the movable table by appending its name to the original class name. In this example, you would use <code>ArticleArchive</code>.

<a name="magic_columns"></a>

Magic columns
-------------

### move_id

By default, restoring a record will only restore itself and not its movable relationships.

To restore the relationships automatically, add the <code>move_id</code> column to all movable tables involved.

### moved_at

If you need to know when the record was moved, add the <code>moved\_at</code> column to your movable table.

See the <a href="#create_the_movable_table">create the movable table</a> section for an example of how to add the magic columns.