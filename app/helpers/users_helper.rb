module UsersHelper
  # Create a map of user role names and the intiger value
  # For use with dropdowns
  def user_roles 
      I18n.t(:user_roles).map { |key, value| [ value, key ] } 
  end
  
  def list_of_products
    Product.order('name')
  end
end
