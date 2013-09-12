class Report < ActiveRecord::Base
  attr_accessible :product_id, :version_id, :start_date, :end_date, :report_type, :second_version_id
  
  belongs_to :product
  belongs_to :version
  belongs_to :second_version, :class_name => "Version"
  belongs_to :user
end
