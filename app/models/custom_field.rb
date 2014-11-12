class CustomField < ActiveRecord::Base
  # Custom fields define the custom entries on items
  # Their values are stored in Custom Items rows
  has_many :custom_items, :dependent => :destroy
  
  validates :item_type, :presence => true
	validates :field_name, :presence => true
	validates :field_type, :presence => true
end
