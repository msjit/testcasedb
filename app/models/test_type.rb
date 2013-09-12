class TestType < ActiveRecord::Base
  attr_accessible :name, :description
  
	has_many :test_cases
	validates :name, :presence => true
	validates :name, :uniqueness => true
end
