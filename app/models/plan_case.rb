class PlanCase < ActiveRecord::Base
  belongs_to :test_plan
  belongs_to :test_case
end
