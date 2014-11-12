class Stencil < ActiveRecord::Base
  attr_accessible :name, :description, :product_id, :status, :custom_items_attributes, :stencil_test_plans_attributes, :created_by_id
  
  belongs_to :product
  belongs_to :created_by, :class_name => "User", :foreign_key => "created_by_id"
  belongs_to :modified_by, :class_name => "User", :foreign_key => "modified_by_id"
  has_many :stencil_test_plans, :dependent => :destroy
  has_many :test_plans, :through => :stencil_test_plans
  has_many :assignments
  has_many :histories
  
  validates :name, :presence => true
  validates :product_id, :presence => true
  
  accepts_nested_attributes_for :stencil_test_plans, :allow_destroy => true
end
