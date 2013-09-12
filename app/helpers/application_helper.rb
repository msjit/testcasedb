module ApplicationHelper

  # Can view a product. Used in views.
  # Simply returns true or false.
  # Equivelant for controllers is called authorize_products. defined in application_controller
  def can_view_product?(product)
    if current_user.products.include?(product)
      return true
    else
      return false
    end
  end
  
  # Create a map of item statuses.
  # For use on items that have the general status list (ex. test cases ad test plans)
  def item_statuses
    # The previous mapping wasn't always in order
    # I18n.t(:history_actions).map { |key, value| [ value ] } 
    # Retrieve translations and sort
    items = I18n.t(:item_status)
    items.map  { |key, value| [ value, key ] } 
  end
  
  # alphabetical list of all products
  def product_list
    current_user.products.order('name').collect {|p| [ p.name, p.id ]}
  end
  
  # Takes a category ID and returns a complete path
  # category as a string
  def CategoryPathName(category_id)
    category = Category.find(category_id)
    name = category.name

    # Is this isn' the parent category keep digging
    # For each parent category, add it to the tree
    while !category.product_id
      category = Category.find(category.category_id)
      name = category.name + '/' + name
    end

    return name
  end
  
  # This function is used for sortable tables
  # Title is optional and used for items whose column name is different than title
  # sort_column and sort_direction are private functions in each controller
  def sortable(column, title = nil)  
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    # In the link to below we added the :product and :versino aprameters
    # these parameters are added to urls by the search function. For example, see the Execute and Versions page
    # We preserve them for use when a search and then order is selected
    link_to title, {:sort => column, :direction => direction, :product => params[:product], :version => params[:version]}, {:class => css_class}
  end
  
end
