require File.expand_path("#{File.dirname(__FILE__)}/../require")
Require.lib!

module Mover
  module Base
    def self.included(base)
      unless base.included_modules.include?(Included)
        base.extend ClassMethods
        base.send :include, Included
      end
    end
  
    module ClassMethods
      def is_movable(*types)
        @movable_types = types
        
        self.class_eval do
          class <<self
            attr_reader :movable_types
          end
        end
        
        extend Table
        extend Record::ClassMethods
        include Record::InstanceMethods
      end
    end
  end
  
  module Migration
    def self.included(base)
      unless base.included_modules.include?(Included)
        base.extend Migrator
        base.send :include, Included
        base.class_eval do
          class <<self
            alias_method :method_missing_without_mover, :method_missing
            alias_method :method_missing, :method_missing_with_mover
          end
        end
      end
    end
  end
  
  module Included
  end
end

ActiveRecord::Base.send(:include, Mover::Base)
ActiveRecord::Migration.send(:include, Mover::Migration)