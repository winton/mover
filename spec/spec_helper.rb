require 'pp'

$root = File.expand_path('../../', __FILE__)
require "#{$root}/lib/mover/gems"

Mover::Gems.activate %w(active_wrapper rspec)

require 'active_wrapper'
require 'fileutils'

require "#{$root}/lib/mover"

require "#{$root}/spec/fixtures/article"
require "#{$root}/spec/fixtures/article_archive"
require "#{$root}/spec/fixtures/comment"
require "#{$root}/spec/fixtures/comment_archive"

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
  keys = values.keys
  (1..5).collect do |x|
    klass.column_names.each do |column|
      next if column == 'id'
      if column == 'article_id' && !keys.include?(:article_id)
        values[:article_id] = x
      elsif !keys.include?(column.intern)
        values[column.intern] = "#{klass} #{x} #{column}"
      end
    end
    record = klass.new
    record.id = x
    record.update_attributes(values)
    record
  end
end