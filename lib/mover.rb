require File.expand_path("#{File.dirname(__FILE__)}/../require")
Require.lib!

module Mover
  def self.included(base)
    unless base.included_modules.include?(InstanceMethods)
      base.extend ClassMethods
      base.send :include, InstanceMethods
      base.send :attr_accessor, :move_options
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

    def move_to(to_class, options={})
      from_class = self
      
      # Conditions
      conditions = options[:conditions] || '1'
      add_conditions!(where = '', conditions)
      conditions = where[5..-1]
      
      # Columns
      magic = options[:magic] || 'moved_at'
      insert = from_class.column_names & to_class.column_names
      insert -= [ magic ]
      insert.collect! { |col| connection.quote_column_name(col) }
      select = insert.clone
      
      # Magic columns
      if to_class.column_names.include?(magic)
        insert << connection.quote_column_name(magic)
        select << connection.quote(Time.now.utc)
      end
      
      # Callbacks
      collector = lambda do |(classes, block)|
        classes.collect! { |c| eval(c.to_s) }
        block if classes.include?(to_class) || classes.empty?
      end
      before = (@before_move || []).collect(&collector).compact
      after = (@after_move || []).collect(&collector).compact
      
      # Instances
      instances =
        if options[:instance]
          [ options[:instance] ]
        elsif before.empty? && after.empty?
          []
        else
          self.find(:all, :conditions => conditions)
        end
      
      # Callback executor
      exec_callbacks = lambda do |callbacks|
        callbacks.each do |block|
          instances.each do |instance|
            instance.move_options = options
            instance.instance_eval(&block)
            instance.move_options = nil
          end
        end
      end
      
      # Execute
      transaction do
        exec_callbacks.call before
        
        if options[:quick]
          connection.execute(<<-SQL)
            INSERT INTO #{to_class.table_name} (#{insert.join(', ')})
            SELECT #{select.join(', ')}
            FROM #{from_class.table_name}
            #{where}
          SQL
        elsif !options[:generic] && connection.class.to_s.include?('Mysql')
          update = insert.collect do |i|
            "#{to_class.table_name}.#{i} = #{from_class.table_name}.#{i}"
          end
          
          connection.execute(<<-SQL)
            INSERT INTO #{to_class.table_name} (#{insert.join(', ')})
            SELECT #{select.join(', ')}
            FROM #{from_class.table_name}
            #{where}
            ON DUPLICATE KEY
            UPDATE #{update.join(', ')};
          SQL
        else
          conditions.gsub!(to_class.table_name, 't')
          conditions.gsub!(from_class.table_name, 'f')
          set = insert.collect { |i| "t.#{i} = f.#{i}" }
          
          connection.execute(<<-SQL)
            UPDATE #{to_class.table_name}
              AS t
            INNER JOIN #{from_class.table_name}
              AS f
            ON f.id = t.id
              AND #{conditions}
            SET #{set.join(', ')}
          SQL
      
          connection.execute(<<-SQL)
            INSERT INTO #{to_class.table_name} (#{insert.join(', ')})
            SELECT #{select.collect { |s| s.include?('`') ? "f.#{s}" : s }.join(', ')}
            FROM #{from_class.table_name}
              AS f
            LEFT OUTER JOIN #{to_class.table_name}
              AS t
            ON f.id = t.id
            WHERE (
              t.id IS NULL
              AND #{conditions}
            )
          SQL
        end
        
        unless options[:copy]
          connection.execute("DELETE FROM #{from_class.table_name} #{where}")
        end
        
        exec_callbacks.call after
      end
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
    
    def move_to(to_class, options={})
      options[:conditions] = "#{self.class.table_name}.#{self.class.primary_key} = #{id}"
      options[:instance] = self
      self.class.move_to(to_class, options)
    end
  end
end

ActiveRecord::Base.send(:include, Mover)