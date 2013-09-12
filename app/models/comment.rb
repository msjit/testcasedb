class Comment < ActiveRecord::Base
  attr_accessible :comment, :test_case_id, :test_plan_id, :task_id
  
  belongs_to :test_case 
  belongs_to :test_plan
  belongs_to :user
  belongs_to :task
    
	validates :user_id, :presence => true
  validates :comment, :presence => true
end
