class Article < ActiveRecord::Base
  has_many :comments
  is_movable :archived
end