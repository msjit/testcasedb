class AuthenticationsController < ApplicationController
  skip_before_filter :require_login, only: [:create, :failure]
  def create
    omniauth = request.env['omniauth.auth']
    authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])  

    if authentication  
      flash[:notice] = "Signed in successfully."
      sign_in_and_redirect(authentication.user)
    elsif current_user  
      current_user.authentications.create(:provider => omniauth['provider'], :uid => omniauth['uid'])  
      redirect_to my_settings_path, :notice => "Authentication successful."  
    else
      redirect_to login_path, :flash => {:error => "User not found."}
    end  
  end

  def failure
    redirect_to :back, :flash => {:error => "Not authorized."}
  end

  def destroy
    @auth = current_user.authentications.find params[:authentication_id]
    @auth.destroy

    redirect_to :back, :notice => "Authentication deleted."
  end
  private
  def sign_in_and_redirect(user)
    unless current_user
      user_session = UserSession.new(user)
      user_session.save
    end
    redirect_to home_path
  end
end
