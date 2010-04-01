class Comment < ActiveRecord::Base
  belongs_to :article
  is_movable :archive
end