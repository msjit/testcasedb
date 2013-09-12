class TasksController < ApplicationController
  # The sortable method requires these
  helper_method :sort_column, :sort_direction

  # GET my/tasks
  # GET /tasks.xml
  def my_index
    authorize! :read, Task
    @tasks = Task.where(:user_id => current_user.id).order(sort_column + " " + sort_direction).page(params[:page]).per(20)

    render "index"
  end

  # GET /tasks
  # GET /tasks.xml
  def index
    authorize! :read, Task
    @tasks = Task.order(sort_column + " " + sort_direction).page(params[:page]).per(20)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /tasks/1
  # GET /tasks/1.xml
  def show
    authorize! :read, Task
    @task = Task.find(params[:id])
    @comment = Comment.new(:task_id => @task.id, :comment => 'Enter a new comment')
    
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /tasks/new
  # GET /tasks/new.xml
  def new
    authorize! :create, Task
    @users_select = User.find(:all, :order => "last_name").collect {|u| [ u.first_name + ' ' + u.last_name, u.id ]}
    
    @task = Task.new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /tasks/1/edit
  def edit
    authorize! :update, Task
    @users_select = User.find(:all, :order => "last_name").collect {|u| [ u.first_name + ' ' + u.last_name, u.id ]}
    
    @task = Task.find(params[:id])    
  end

  # POST /tasks
  # POST /tasks.xml
  def create
    authorize! :create, Task
    @task = Task.new(params[:task])
    @comment = Comment.new(:task_id => @task.id, :comment => 'Enter a new comment')
    
    respond_to do |format|
      if @task.save
        @url = task_path(@task, :only_path => false)
        begin
          UserMailer.task_assigned(@task, @url).deliver
          format.html { redirect_to(@task, :notice => 'Task was successfully created.') }
        rescue
          format.html { redirect_to(@task, :flash => { :warning => 'Task was successfully created, but there was an error sending the notification email.'}) }
        end
      else
        @users_select = User.find(:all, :order => "last_name").collect {|u| [ u.first_name + ' ' + u.last_name, u.id ]}
        
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /tasks/1
  # PUT /tasks/1.xml
  def update
    authorize! :update, Task
    @task = Task.find(params[:id])
    
    respond_to do |format|
      if @task.update_attributes(params[:task])
        # If status is complete, but completion date is blank, set it to today
        if (@task.status == 127) &&  (!@task.completion_date)
          @task.completion_date = Date.today
          @task.save
        end
          
        format.html { redirect_to(@task, :notice => 'Task was successfully updated.') }
      else
        @users_select = User.find(:all, :order => "last_name").collect {|u| [ u.first_name + ' ' + u.last_name, u.id ]}
        
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /tasks/1
  # DELETE /tasks/1.xml
  def destroy
    authorize! :destroy, Task
    @task = Task.find(params[:id])
    @task.destroy

    respond_to do |format|
      format.html { redirect_to(tasks_url) }
    end
  end
  
  private
  
  # Functions for sorting columns
  # Among other things, these prevent SQL injection
  # Set asc and name as default values
  def sort_column
    Task.column_names.include?(params[:sort]) ? params[:sort] : "name"
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
