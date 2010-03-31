module Mover
  module Base
    module Table
      
      def create_movable_table(type, options={})
        movable_table = [ type, table_name ].join('_')
        columns =
          if options[:columns]
            options[:columns].collect { |c| "`#{c}`" }.join(', ')
          else
            '*'
          end
        engine = options[:engine]
        engine ||=
          if connection.class.to_s.include?('Mysql')
            "ENGINE=InnoDB"
          end
        if table_exists? and !connection.table_exists?(movable_table)
          # Create table
          connection.execute(<<-SQL)
            CREATE TABLE #{movable_table} #{engine}
            AS SELECT #{columns}
            FROM #{table_name}
            WHERE false;
          SQL
          # Create extra columns
          (options[:extra_columns] || {}).each do |column, type|
            connection.add_column(movable_table, column, type)
          end
          # Create indexes
          options[:indexes] ||= indexed_columns(table_name)
          options[:indexes].each do |column|
            connection.add_index(movable_table, column)
          end
        end
      end
    
      def drop_movable_table(*types)
        types.each do |type|
          connection.execute("DROP TABLE IF EXISTS #{[ type, table_name ].join('_')}")
        end
      end
      
      private
      
      def indexed_columns(table_name)
        # MySQL
        if connection.class.to_s.include?('Mysql')
          index_query = "SHOW INDEX FROM #{table_name}"
          indexes = connection.select_all(index_query).collect do |r|
            r["Column_name"]
          end
        # PostgreSQL
        elsif connection.class.to_s.include?('PostgreSQL')
          # http://stackoverflow.com/questions/2204058/show-which-columns-an-index-is-on-in-postgresql/2213199#2213199
          index_query = <<-SQL
            select
              t.relname as table_name,
              i.relname as index_name,
              a.attname as column_name
            from
              pg_class t,
              pg_class i,
              pg_index ix,
              pg_attribute a
            where
              t.oid = ix.indrelid
              and i.oid = ix.indexrelid
              and a.attrelid = t.oid
              and a.attnum = ANY(ix.indkey)
              and t.relkind = 'r'
              and t.relname = '#{table_name}'
            order by
              t.relname,
              i.relname
          SQL
          indexes = connection.select_all(index_query).collect do |r|
            r["column_name"]
          end
        else
          raise 'Mover does not support this database adapter'
        end
      end
    end
  end
end