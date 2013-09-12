class History < ActiveRecord::Base
  belongs_to :test_case
  belongs_to :test_plan
  belongs_to :result
  belongs_to :assignment
  belongs_to :user
  belongs_to :product
  belongs_to :category
  belongs_to :task
  belongs_to :stencil
  has_many :test_cases, :through => :result
  has_many :test_plans, :through => :assignment
end
