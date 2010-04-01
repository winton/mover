module Mover
  module Base
    module Record
      module ClassMethods
        
        def move_from(type, conditions)
          klass = movable_class(type)
          if klass
            if klass.column_names.include?('move_id')
              klass.find_each(:conditions => conditions) do |record|
                record.move_from
              end
            else
              execute_move(klass, self, conditions)
            end
          end
        end
        
        def move_to(type, conditions)
          if movable_class(type).column_names.include?('move_id')
            self.find_each(:conditions => conditions) do |record|
              record.move_to(type)
            end
          else
            execute_move(self, movable_class(type), conditions)
          end
        end
        
        private
        
        def execute_move(from_class, to_class, conditions, &block)
          add_conditions! where = '', conditions
          insert = from_class.column_names & to_class.column_names
          insert.collect! { |col| connection.quote_column_name(col) }
          select = insert.clone
          yield(insert, select) if block_given?
          if to_class.column_names.include?('moved_at')
            insert << connection.quote_column_name('moved_at')
            select << connection.quote(Time.now)
          end
          connection.execute(<<-SQL)
            INSERT INTO #{to_class.table_name} (#{insert.join(', ')})
            SELECT #{select.join(', ')}
            FROM #{from_class.table_name}
            #{where}
          SQL
          connection.execute("DELETE FROM #{from_class.table_name} #{where}")
        end
        
        def movable_class(type)
          eval(self.name + type.to_s.classify)
        rescue
          raise "#{self.table_name.classify} needs an `is_movable :#{type}` definition"
        end
      end
    
      module InstanceMethods
        
        def move_from
          return unless self.respond_to?(:moved_from_class)
          # Move associations
          moved_from_class.reflect_on_all_associations.each do |association|
            if move_association?(association)
              klass = association.klass.send(:movable_class, self.class.movable_type)
              klass.find_each(:conditions => [ 'move_id = ?', self.move_id ]) do |record|
                record.move_from
              end
            end
          end
          # Move record
          conditions = "#{self.class.primary_key} = #{id}"
          moved_from_class.send(:execute_move, self.class, moved_from_class, conditions)
        end
        
        def move_to(type)
          return if self.respond_to?(:moved_from_class)
          klass = self.class.send :movable_class, type
          if klass
            # Create movable_id
            if !self.movable_id && klass.column_names.include?('move_id')
              self.movable_id = Digest::MD5.hexdigest("#{self.class.name}#{self.id}")
            end
            # Move associations
            self.class.reflect_on_all_associations.each do |association|
              if move_association?(association)
                self.send(association.name).each do |record|
                  record.movable_id = self.movable_id
                  record.move_to(type)
                end
              end
            end
            # Move record
            me = self
            conditions = "#{self.class.primary_key} = #{id}"
            self.class.send(:execute_move, self.class, klass, conditions) do |insert, select|
              if me.movable_id
                insert << connection.quote_column_name('move_id')
                select << connection.quote(self.movable_id)
              end
            end
            self.movable_id = nil
          end
        end
        
        private
        
        def move_association?(association)
          association.klass.respond_to?(:movable_types) &&
          association.macro.to_s =~ /^has/
        end
      end
    end
  end
end