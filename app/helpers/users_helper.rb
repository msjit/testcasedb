module UsersHelper
  # Create a map of user role names and the intiger value
  # For use with dropdowns
  def user_roles 
      I18n.t(:user_roles).map { |key, value| [ value, key ] } 
  end
  
  def list_of_products
    Product.order('name')
  end
  
  # Generate a url for a certain authorization
  # Returns an empty string in case that there is no authorization
  # for that type
  def delete_auth_for(user, auth_provider)
    auth = user.auth_for(auth_provider)
    if auth
      authentication_delete_path(auth)
    else
      ''
    end
  end
end
