class ScheduleRun < ActiveRecord::Base
  belongs_to :device
  
  validates :device_id, :presence => true
  validates :start_time, :presence => true
end
