class CustomItem < ActiveRecord::Base
  # Custom items are the values derived from custom fields
  belongs_to :test_case
  belongs_to :test_plan
  belongs_to :assignment
  belongs_to :result
  belongs_to :device
  belongs_to :custom_field
  
	validates :custom_field_id, :presence => true
	
end
