class Setting < ActiveRecord::Base
  attr_accessible :value, :name, :description
  
  validates :name, :presence => true
	validates :name, :uniqueness => true
	validates :value, :presence => true

  # This function returns the value of a setting
  # Settings are retrieved by name
  # If there is no setting, nil is returned
  # For Enabled/Disabled, true/false are returned
  # Otherwise the value is returned
	def self.value (name)
    entry = Setting.find_by_name(name)
    
    if !entry 
      return nil
    elsif entry.value == "Enabled"
      return true
    elsif entry.value == "Disabled"
      return false
    else
      return entry.value
    end
  end
end
