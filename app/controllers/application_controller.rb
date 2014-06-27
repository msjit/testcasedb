class ApplicationController < ActionController::Base
  protect_from_forgery


  # When Product authorization is checked, the error below is generated on a failure
  # This redirects the user to the home page with an auth error
  rescue_from Exceptions::ProductAccessDenied do |exception|
    redirect_to home_url, :flash => {:warning => "You do not have access to this product. Contact your administrator to gain access." }
  end

  # When CanCan authorization fails an error is generated
  # This redirects the user to the home page with an auth error
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to home_url, :flash => {:warning => exception.message }
  end
  
  # For all pages, require that the user be logged in
  # Note that this filter is ignored in the user_session and authentication controller
  # As it would break login
  before_filter :require_login
  before_filter :set_user_time_zone
  
  helper_method :current_user
  # For solution for default_url_options
  helper_method :url_for
  
  # In our views, we use jquery.get with the _url option.
  # When running with passenger, it always makes the URL http
  # even if https is used. We use the _url because of Sub URI installs
  # To resolve the missing https, we've added a config option to config/application.rb
  # When the environment is a production env and https is true we manual set urls
  # to https. We only do for production, so devs do not need to worry about this.
  def default_url_options(options ={})
    if Rails.env.production?
      if TestDB::Application.config.ssl_enabled == true
        options.merge({ :only_path => false, :protocol => 'https' })
      else
        options.merge({})
      end
    else
      options.merge({}) 
    end
    
  end

  # /update_version_select/1
  # Get the versions for the current product
  # Then render the small versions drop down partial for index search
  # This is used for searches on index pages with a product.
  # Ex. see assignments and and results (execute) index page
  def update_version_select        
    versions = Version.where(:product_id => params[:id]).order(:version) unless params[:id].blank?
    render :partial => "versions", :locals => { :versions => versions }
  end
  
  private

  # Verify user is logged in
  # If not refer to login page
  def require_login
    unless current_user
      redirect_to login_path(:referer => request.fullpath)
      return false
    end
  end

  # Authorize product raises an exception if user tries to a access a product that they do not have access to
  # This is used in controller. The check for views is in the application helper
  def authorize_product!(product)
    unless current_user.products.include?(product)
      raise Exceptions::ProductAccessDenied
    end
  end
  
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.record
  end
  
  
  # Call to set timezone for user
  def set_user_time_zone
    Time.zone = current_user.time_zone if current_user
  end
  
  # Traverses the category tree to find the parent category
  # Finds the product_id set for the parent category
  # Returns the product_id
  def get_product_id_from_category_id(category_id)
    authorize! :read, TestCase
    
    category = Category.find(category_id)

    if category.product_id
      return category.product_id
    else
      return get_product_id_from_category_id(category.category_id)
    end
  end
  
  def google_auth_enabled
    @google_auth_enabled = Setting.value('Google Auth enabled')
  end
  
end
