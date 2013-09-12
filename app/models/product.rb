class Product < ActiveRecord::Base
  attr_accessible :name, :description, :user_ids
  
	has_many :test_plans
	has_many :versions, :dependent => :destroy
	has_many :assignments
	has_many :categories, :dependent => :destroy
	has_many :reports
	has_many :schedules
	has_many :product_users, :dependent => :destroy
  has_many :users, :through => :product_users
  has_many :requirements
	
	validates :name, :presence => true
	validates :name, :uniqueness => true
end
