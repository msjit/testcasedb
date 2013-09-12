module ProductsHelper
  
  def list_of_users
    # User.order('last_name, first_name').collect {|u| [ u.last_name + ', ' + u.first_name  + ' - ' + u.email, u.id]}
    User.order('last_name, first_name')
  end
end
