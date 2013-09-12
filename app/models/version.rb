class Version < ActiveRecord::Base
  attr_accessible :version, :description, :product_id
  
  belongs_to :product
  has_many :assignments
  has_many :reports
  validates :version, :presence => true
  validates :product_id, :presence => true
end
