class Assignment < ActiveRecord::Base  
  	belongs_to :product
	belongs_to :version
	belongs_to :test_plan
	belongs_to :schedule
	belongs_to :stencil
	has_many :results, :dependent => :destroy
  	has_many :test_cases, :through => :results
 	has_one :task
  	has_many :custom_items, :dependent => :destroy
  	has_many :custom_fields, :through => :custom_items

	accepts_nested_attributes_for :task, :custom_items
  			attr_accessible :notes, :product_id, :version_id, :test_plan_id, :stencil_id, :schedule_id, :task_attributes, :custom_items_attributes

	validates :product_id, :presence => true
	validates :version_id, :presence => true
end
