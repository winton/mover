require File.expand_path("#{File.dirname(__FILE__)}/../require")
Require.spec_helper!

Spec::Runner.configure do |config|
end

$db, $log = ActiveWrapper.setup(
  :base => File.dirname(__FILE__),
  :env => 'test'
)
$db.establish_connection

def article_match?(original, copy)
  copy.id.should == original.id
  copy.title.should == original.title
  copy.body.should == original.body
  copy.read.should == original.read
end

def columns(table)
  connection.columns(table).collect(&:name)
end

def connection
  ActiveRecord::Base.connection
end

def create_records(klass=Article, values={})
  klass.delete_all
  (1..5).collect do |x|
    klass.column_names.each do |column|
      values[column.intern] = "#{x} #{column}"
    end
    values[:id] = x
    Article.create(values)
  end
end

def migrate_with_state(version)
  @old_article_columns = columns("articles")
  @old_archive_columns = columns("archived_articles")
  $db.migrate(version)
  @new_article_columns = columns("articles")
  @new_archive_columns = columns("archived_articles")
end