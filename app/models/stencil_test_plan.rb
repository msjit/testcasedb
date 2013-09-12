class StencilTestPlan < ActiveRecord::Base
  default_scope :order => 'plan_order ASC'
  
  belongs_to :test_plan
  belongs_to :stencil
  belongs_to :device
  
  validates :test_plan_id, :presence => true
  validates :device_id, :presence => true
end
