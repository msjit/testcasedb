class UserSessionsController < ApplicationController
  # Ignore the require login filter or we get stuck in 
  # a redirect loop to this page  
  skip_before_filter :require_login
  skip_before_filter :set_user_time_zone
  before_filter :google_auth_enabled
  
  def new
    @user_session = UserSession.new
    render :layout => false
  end

  def create
    @user_session = UserSession.new(params[:user_session])
        
    if @user_session.save
      if params[:user_session][:referer]
        redirect_to params[:user_session][:referer], :notice => "Successfully logged in."
      else  
        redirect_to home_path, :notice => "Successfully logged in."
      end
    else
      render :action => 'new', :layout => false, :test => 'Invalid username or password'
    end
  end

  def destroy
    # Delet old session 
    user_session = UserSession.find
    user_session.destroy if user_session
    
    # Prepare new session
    @user_session = UserSession.new
    render :action => 'new', :layout => false, :notice => "Logged out."
  end
end
