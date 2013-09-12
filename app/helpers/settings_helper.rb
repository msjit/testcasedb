module SettingsHelper
  def ticket_systems_list 
      I18n.t(:ticketing_systems).map { |key, value| [ value, key ] } 
  end
end
