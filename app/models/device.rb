class Device < ActiveRecord::Base
  attr_accessible :name, :description, :active, :custom_items_attributes
  
  has_many :schedules, :dependent => :destroy
  has_many :schedule_runs
  has_many :results
  has_many :custom_items, :dependent => :destroy
	has_many :custom_fields, :through => :custom_items

	accepts_nested_attributes_for :custom_items
	  
  validates :name, :presence => true
end
