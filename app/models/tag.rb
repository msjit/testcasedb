class Tag < ActiveRecord::Base
  has_many :tag_test_cases, :dependent => :destroy
	has_many :test_cases, :through => :tag_test_cases
  
  validates :name, :presence => true
	validates :name, :uniqueness => true
end
