require File.dirname(__FILE__) + '/mover/gems'

$:.unshift File.dirname(__FILE__)

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
      conditions = self.sanitize_sql(conditions)
      where = "WHERE #{conditions}"
      
      # Columns
      magic = options[:magic] || 'moved_at'
      from = {
        :columns => from_class.column_names,
        :table => from_class.table_name
      }
      to = {
        :database => to_class.connection.current_database,
        :columns => to_class.column_names,
        :table => to_class.table_name
      }
      
      # insert[column] = value
      insert = (from[:columns] & to[:columns]).inject({}) do |hash, column|
        if column == magic && !options[:migrate]
          hash[column] = Time.now.utc
        else
          hash[column] = column
        end
        hash
      end
      
      # Magic column not in "from" table
      if to[:columns].include?(magic) && !from[:columns].include?(magic)
        insert[magic] = Time.now.utc
      end
      
      # Quote everything
      insert = insert.inject({}) do |hash, (column, value)|
        if value.is_a?(::Time)
          hash[connection.quote_column_name(column)] = connection.quote(value)
        else
          hash[connection.quote_column_name(column)] = connection.quote_column_name(value)
        end
        hash
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
      options.delete(:instance)
      
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
            INSERT INTO #{to[:database]}.#{to[:table]} (#{insert.keys.join(', ')})
            SELECT #{insert.values.join(', ')}
            FROM #{from[:table]}
            #{where}
          SQL
        elsif !options[:generic] && connection.class.to_s.include?('Mysql')
          update = insert.collect do |column, value|
            if value.include?("'")
              "#{to[:table]}.#{column} = #{value}"
            else
              "#{to[:table]}.#{column} = #{from[:table]}.#{value}"
            end
          end
          connection.execute(<<-SQL)
            INSERT INTO #{ to[:database]}.#{to[:table]} (#{insert.keys.join(', ')})
            SELECT #{insert.values.join(', ')}
            FROM #{from[:table]}
            #{where}
            ON DUPLICATE KEY
            UPDATE #{update.join(', ')};
          SQL
        else
          conditions.gsub!(to[:table], 't')
          conditions.gsub!(from[:table], 'f')
          select = insert.values.collect { |i| i.include?("'") ? i : "f.#{i}" }
          set = insert.collect do |column, value|
            if value.include?("'")
              "t.#{column} = #{value}"
            else
              "t.#{column} = f.#{value}"
            end
          end
          
          connection.execute(<<-SQL)
            UPDATE #{to[:table]}
              AS t
            INNER JOIN #{from[:table]}
              AS f
            ON f.id = t.id
              AND #{conditions}
            SET #{set.join(', ')}
          SQL
      
          connection.execute(<<-SQL)
            INSERT INTO #{to[:table]} (#{insert.keys.join(', ')})
            SELECT #{select.join(', ')}
            FROM #{from[:table]}
              AS f
            LEFT OUTER JOIN #{to[:table]}
              AS t
            ON f.id = t.id
            WHERE (
              t.id IS NULL
              AND #{conditions}
            )
          SQL
        end
        
        unless options[:copy]
          connection.execute("DELETE FROM #{from[:table]} #{where}")
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
