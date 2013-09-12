class Step < ActiveRecord::Base
  attr_accessible :action, :result, :step_number, :test_case_id
  
  belongs_to :test_cases
end
