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
        end
      end
    end
  end
end