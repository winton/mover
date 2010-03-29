require File.expand_path("#{File.dirname(__FILE__)}/../require")
Require.lib!

module Mover
  module Base
    def self.included(base)
      unless base.included_modules.include?(Included)
        base.extend ClassMethods
        base.include Included
      end
    end
  
    module ClassMethods
      def is_movable(*types)
        self.attr_reader :is_moveable?
        self.attr_reader :moveable_types
        
        self.is_moveable? = true
        self.moveable_types = types
        
        extend CreateTable
        extend RestoreRecord
        include MoveRecord
      end
    end
  end
  
  module Migration
    def self.included(base)
      unless base.included_modules.include?(Included)
        base.extend Migrator
        base.include Included
        base.class_eval do
          self.alias_method :method_missing_without_mover, :method_missing
          self.alias_method :method_missing, :method_missing_with_mover
        end
      end
    end
  end
  
  module Included
  end
end

ActiveRecord::Base.send(:include, Mover::Base)
ActiveRecord::Migration.send(:include, Mover::Migration)