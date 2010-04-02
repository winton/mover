require File.expand_path("#{File.dirname(__FILE__)}/../require")
Require.spec_helper!

Spec::Runner.configure do |config|
end

$db, $log = ActiveWrapper.setup(
  :base => File.dirname(__FILE__),
  :env => 'test'
)
$db.establish_connection

def record_match?(original, copy)
  (original.class.column_names & copy.class.column_names).each do |col|
    copy.send(col).should == original.send(col)
  end
end

def columns(table)
  connection.columns(table).collect(&:name)
end

def connection
  ActiveRecord::Base.connection
end

def create_records(klass, values={})
  klass.delete_all
  (1..5).collect do |x|
    klass.column_names.each do |column|
      if column == 'article_id'
        values[:article_id] = x
      else
        values[column.intern] = "#{klass} #{x} #{column}"
      end
    end
    values[:id] = x
    klass.create(values)
  end
end