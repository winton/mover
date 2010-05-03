require File.expand_path("#{File.dirname(__FILE__)}/../require")
Require.lib!

module Mover
  def self.included(base)
    unless base.included_modules.include?(InstanceMethods)
      base.extend ClassMethods
      base.send :include, InstanceMethods
    end
  end
  
  module ClassMethods
    
    def after_move(*to_class, &block)
      @after_move ||= []
      @after_move << [ to_class, block ]
    end
    
    def before_move(*to_class, &block)
      @before_move ||= []
      @before_move << [ to_class, block ]
    end
    
    def after_copy(*to_class, &block)
      @after_copy ||= []
      @after_copy << [ to_class, block ]
    end

    def before_copy(*to_class, &block)
      @before_copy ||= []
      @before_copy << [ to_class, block ]
    end

    def move_to(to_class, conditions, instance=nil, copy = false)
      from_class = self
      # Conditions
      add_conditions! where = '', conditions
      # Columns
      insert = from_class.column_names & to_class.column_names
      insert -= [ 'moved_at' ]
      insert.collect! { |col| connection.quote_column_name(col) }
      select = insert.clone
      # Magic columns
      if to_class.column_names.include?('moved_at')
        insert << connection.quote_column_name('moved_at')
        select << connection.quote(Time.now.utc)
      end
      # Callbacks
      collector = lambda do |(classes, block)|
        classes.collect! { |c| eval(c.to_s) }
        block if classes.include?(to_class) || classes.empty?
      end
      if copy
        before = (@before_copy || []).collect(&collector).compact
        after = (@after_copy || []).collect(&collector).compact
      else # move
        before = (@before_move || []).collect(&collector).compact
        after = (@after_move || []).collect(&collector).compact
      end
      # Instances
      instances =
        if instance
          [ instance ]
        elsif before.empty? && after.empty?
          []
        else
          self.find(:all, :conditions => where[5..-1])
        end
      # Callback executor
      exec_callbacks = lambda do |callbacks|
        callbacks.each do |block|
          instances.each { |instance| instance.instance_eval(&block) }
        end
      end
      # Execute
      transaction do
        exec_callbacks.call before
        connection.execute(<<-SQL)
          INSERT INTO #{to_class.table_name} (#{insert.join(', ')})
          SELECT #{select.join(', ')}
          FROM #{from_class.table_name}
          #{where}
        SQL
        connection.execute("DELETE FROM #{from_class.table_name} #{where}") unless copy
        exec_callbacks.call after
      end
    end

    def copy_to(to_class, conditions, instance=nil)
      move_to(to_class, conditions, instance, true)
    end

    def reserve_id
      id = nil
      transaction do
        id = connection.insert("INSERT INTO #{self.table_name} () VALUES ()")
        connection.execute("DELETE FROM #{self.table_name} WHERE id = #{id}") if id
      end
      id
    end
  end
  
  module InstanceMethods
    def move_to(to_class)
      self.class.move_to(to_class, "#{self.class.primary_key} = #{id}", self)
    end

    def copy_to(to_class)
      self.class.copy_to(to_class, "#{self.class.primary_key} = #{id}", self)
    end
  end
end

ActiveRecord::Base.send(:include, Mover)