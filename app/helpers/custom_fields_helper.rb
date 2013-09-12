module CustomFieldsHelper
  def custom_field_item_types_list 
      I18n.t(:custom_field_item_types).map { |key, value| [ value, key ] } 
  end
  
  def custom_field_types_list 
      I18n.t(:custom_field_types).map { |key, value| [ value, key ] } 
  end
end
