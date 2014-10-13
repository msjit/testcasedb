class UsersController < ApplicationController
  # The sortable method requires these
  helper_method :sort_column, :sort_direction
  before_filter :google_auth_enabled, :only => [:my_settings]

  # GET /users
  def index
    authorize! :read, User
    @users = User.order(sort_column + " " + sort_direction).page(params[:page]).per(20)
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def new
    @user = User.new
    authorize! :create, @user
  end

  def create
    @user = User.new(params[:user])
    authorize! :create, @user

    if @user.save
      # If this is save and new, redirect to new user page
      if params[:commit] == "Save and Create Additional"
        redirect_to new_user_path, :notice => 'User successfully created. Please create another.'
        # If it is just save, show the new user
      else
        redirect_to users_path, :notice => "Successfully created user." 
      end
    else
      render :action => 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
    authorize! :update, @user
  end

  def update
    @user = User.find(params[:id])
    authorize! :update, @user
    
    # If this is an admin user, we need to make sure that
    # we do not allow the role to change or active set false if it is
    # the only active admin
    # 
    # make sure if this is the only active admin that their role is not changed
    if (@user.role == 10) && (User.where("role = 10 AND active = true").count == 1) && (params[:user][:role] != '10')
      redirect_to edit_user_path(@user), :flash => {:warning => "There must be at least one active administrator. Changes not saved"}
    # make sure if this is the only active admin that they are not set inactive
    elsif (@user.role == 10) && (User.where("role = 10 AND active = true").count == 1) && (params[:user][:active] == '0') 
      redirect_to edit_user_path(@user), :flash => {:warning => "There must be at least one active administrator. Changes not saved"}
    # otherwise allow changes. so proceed per normal
    else  
      if @user.update_attributes(params[:user])
        redirect_to users_path, :notice  => "Successfully updated user."
      else
        render :action => 'edit', :flash => {:warning => "There was an issue updating the user."}
      end
    end
  end
  
  def import
    if request.post?
      # open the spread sheet and prepare variables
      @errors = User.import(params[:user][:upload])
      if @errors.blank?
        redirect_to users_path, notice: "Users imported."
      else
        render "import_form"
      end
    else
      render "import_form"
    end
  end
  
  # /my_settings
  def my_settings
    @user = User.find(current_user.id)
  end

  # /update_settings   
  def update_my_settings
    @user = User.find(current_user.id)
    
    # Users should not alter the following fields
    # role, active, username. Therefore, when we see these in the request, we discard
    # Note that if they're included, likely they are trying to hack the system
    # Unfortunately, they are attr_accessible as admins need access
    if params[:user][:role] or params[:user][:username] or params[:user][:active]
      redirect_to home_path, :flash => {:warning => "Unable to make the changes."}
    else
      # If this is a valid request, try to update the attributes as per normal
      if @user.update_attributes(params[:user])
        redirect_to home_path, :notice => 'Changes successfully saved.'
      else
        render :action => 'my_settings', :flash => {:warning => "There was an issue updating your settings."}
      end
    end
  end
  
  def reset
    @user = User.find(params[:id])
    authorize! :create, @user
    
    @user.failed_login_count = 0
    @user.save
    
    redirect_to users_path, :notice => 'User account unlocked'
  end
  
  private
  
  def sort_column
    User.column_names.include?(params[:sort]) ? params[:sort] : "username"
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
  
  def single_access_allowed?
    action_name == "run"
  end
end
