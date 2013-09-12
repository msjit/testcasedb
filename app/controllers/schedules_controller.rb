class SchedulesController < ApplicationController
  # The sortable method requires these
  helper_method :sort_column, :sort_direction
  
  # README FIRST!!!!!!
  # There is a major issue with this controller that requires a workaround
  # The time data type used for start_time does not contain a timezone. As a result,
  # all times are stored as the user sees them, not in UTC time
  # This breaks the rake scheduler. As a result we have created to functions to convert times
  # to utc and back the must be used in all functions that deal with start time
  
  
  
  # GET /schedules
  # GET /schedules.xml
  def index
    authorize! :read, Schedule
    @schedules = Schedule.includes(:product, :device, :test_plan).where(:product_id => current_user.products).order(sort_column + " " + sort_direction)
    
    @schedules.each do |schedule|
      schedule.start_time = convert_to_local_time(schedule.start_time)
    end
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /schedules/1
  # GET /schedules/1.xml
  def show
    @schedule = Schedule.find(params[:id])
    @schedule.start_time = convert_to_local_time(@schedule.start_time)
    authorize! :read, @schedule
    
    # Verify user can view this schedule. Must be in his product
    authorize_product!(@schedule.product)
    
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /schedules/new
  # GET /schedules/new.xml
  def new
    @schedule = Schedule.new
    authorize! :create, @schedule
    
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /schedules/1/edit
  def edit
    @schedule = Schedule.find(params[:id])
    @schedule.start_time = convert_to_local_time(@schedule.start_time)
    authorize! :update, @schedule
    
    # Verify user can view this schedule. Must be in his product
    authorize_product!(@schedule.product)
    
  end

  # POST /schedules
  # POST /schedules.xml
  def create
    @schedule = Schedule.new(params[:schedule])
    authorize! :create, @schedule
    
    # Verify user can view this schedule. Must be in his product
    authorize_product!(@schedule.product)

    respond_to do |format|
      if @schedule.save
        @schedule.start_time = convert_to_utc_time(@schedule.start_time)
        @schedule.save
        format.html { redirect_to(@schedule, :notice => 'Schedule was successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /schedules/1
  # PUT /schedules/1.xml
  def update
    @schedule = Schedule.find(params[:id])
    authorize! :update, @schedule

    # Verify user can view this schedule. Must be in his product
    authorize_product!(@schedule.product)
    # Verify that if they change the product, it is changed to a product they have access to.
    authorize_product!(Product.find(params[:schedule][:product_id]))
    
    respond_to do |format|
      if @schedule.update_attributes(params[:schedule])
        @schedule.start_time = convert_to_utc_time(@schedule.start_time)
        @schedule.save
        format.html { redirect_to(@schedule, :notice => 'Schedule was successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /schedules/1
  # DELETE /schedules/1.xml
  def destroy
    @schedule = Schedule.find(params[:id])
    authorize! :destroy, @schedule
    
    # Verify user can view this schedule. Must be in his product
    authorize_product!(@schedule.product)
    
    @schedule.destroy

    respond_to do |format|
      format.html { redirect_to(schedules_url) }
    end
  end
  
  # scheduless/update_test_plan_select/1
  # Get the test plans for the current product
  # Then render the test plan drop down partial
  def update_test_plan_select        
    test_plans = TestPlan.where(:product_id => params[:id]).order(:name) unless params[:id].blank?

    # Verify user can view this schedule. Must be in his product
    authorize_product!(Product.find(params[:id]))
    
    render :partial => "test_plans", :locals => { :test_plans => test_plans }
  end

  # Takes a UTC TIME and returns time local time based on user timezone
  def convert_to_local_time(utc_time)
    utc_time + Time.current.utc_offset
  end
  
  # Takes a local user time and returns UTC
  def convert_to_utc_time(utc_time)
    utc_time - Time.current.utc_offset
  end
  
  private
  
  # Functions for sorting columns
  # Among other things, these prevent SQL injection
  # Set asc and name as default values
  def sort_column
    # Schedule.column_names.include?(params[:sort]) ? params[:sort] : "device_id"
    %w[devices.name products.name test_plans.name start_time].include?(params[:sort]) ? params[:sort] : "devices.name"
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
