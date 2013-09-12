class Task < ActiveRecord::Base
  attr_accessible :user_id, :task, :description, :due_date, :completion_date, :status, :name, :assignment_id
  
  belongs_to :user
  has_many :comments, :dependent => :destroy
	belongs_to :assignment
	has_many :results, :through => :assinment
  validates :user_id, :presence => true
  validates :due_date, :presence => true  
  validates :task, :presence => true
  validates :status, :presence => true
  validates :name, :presence => true
end
