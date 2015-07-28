class Result < ActiveRecord::Base
  attr_accessible :result, :note, :bugs, :assignment_id, :test_case_id, :device_id, :executed_at, :custom_items_attributes
  
  belongs_to :test_case
  belongs_to :assignment
  belongs_to :device
  has_one :task, :through => :assignment
  has_one :test_plan, :through => :assignment
  has_many :plan_cases, -> { order(:case_order) }, :through => :assignment, :source => :test_plan
	has_many :uploads, :as => :uploadable, :dependent => :destroy
  has_many :custom_items, :dependent => :destroy
  has_many :custom_fields, :through => :custom_items
  has_many :result_statistics, :dependent => :destroy
  has_many :test_case_targets, :through => :test_case
  
  validates_format_of :bugs, :with => /\A[-a-zA-Z0-9]+([-a-zA-Z0-9,]+)*\z/, :allow_nil => true, :allow_blank => true

  accepts_nested_attributes_for :custom_items
end
