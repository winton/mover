module Mover
  module Base
    module Record
      module ClassMethods
        def move_from(*types)
          conditions = types.pop
        end
      end
    
      module InstanceMethods
        def move_to(*types)
          self.class.send :add_conditions!, where = '', "#{self.class.primary_key} = #{id}"
          types.each do |type|
            movable_table = [ type, self.class.table_name ].join('_')
            klass = eval(type.to_s.classify + self.class.table_name.classify)
            if klass
              cols = klass.column_names.clone
              cols.collect! { |col| connection.quote_column_name(col) }
              connection.execute(<<-SQL)
                INSERT INTO #{movable_table} (#{cols.join(', ')})
                SELECT #{cols.join(', ')}
                FROM #{self.class.table_name}
                #{where}
              SQL
              connection.execute("DELETE FROM #{self.class.table_name} #{where}")
            end
          end
        end
      end
    end
  end
end