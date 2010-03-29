module Mover
  module Migrator
    
    def method_missing_with_mover(method, *arguments, &block)
      args = Marshal.load(Marshal.dump(arguments))
      method_missing_without_mover(method, *arguments, &block)
      supported = [
        :add_column, :add_timestamps, :change_column,
        :change_column_default, :change_table,
        :drop_table, :remove_column, :remove_columns,
        :remove_timestamps, :rename_column, :rename_table
      ]
      %w(moved_at move_id).each do |column|
        if args.include?(column) || args.include?(column.intern)
          return # Don't change the column
        end
      end
      if !args.empty? && supported.include?(method)
        connection = ActiveRecord::Base.connection
        table_name = ActiveRecord::Migrator.proper_table_name(args[0])
        klass = class_from_table_name(table_name)
        if klass
          klass.moveable_types.each do |type|
            args[0] = [ type, table_name ].join('_')
            if method == :rename_table
              args[1] = [ type, args[1].to_s ].join('_')
            end
            if connection.table_exists?(args[0])
              connection.send(method, *args, &block)
            end
          end
        end
      end
    end
    
    def class_from_table_name(table_name)
      Object.subclasses_of(ActiveRecord::Base).detect do |klass|
        if klass.respond_to?(:is_moveable?) && klass.is_moveable?
          klass.table_name.to_s == table_name
        end
      end
    end
  end
end