class ReportsController < ApplicationController
  # GET /reports
  # GET /reports.xml
  def index
    authorize! :read, Report
    @reports = Report.where(:user_id => current_user.id)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /reports/1
  # GET /reports/1.xml
  def show
    authorize! :read, Report  
    @report = Report.find(params[:id])

    # Since they can only see their own reports this isn't absolutely required, but we hve this as anextra layer of precaution    
    # Verify user can view this report. Must be in his product
    unless @report.product.nil?
      authorize_product!(@report.product)
    end
    
    if @report.user_id == current_user.id
      render
    else
      redirect_to reports_url, :flash => { :warning => "You do not have access to this report." }
    end
  end

  # GET /reports/new
  # GET /reports/new.xml
  def new
    authorize! :create, Report
    @report = Report.new
    
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /reports/1/edit
  def edit
    authorize! :update, Report
    @report = Report.find(params[:id])

    # Since they can only see their own reports this isn't absolutely required, but we hve this as anextra layer of precaution    
    # Verify user can view this report. Must be in his product
    unless @report.product.nil?
      authorize_product!(@report.product)
    end
        
    if @report.user_id == current_user.id
      render
    else
      redirect_to reports_url, :flash => { :warning => "You do not have access to this report." }
    end
  end

  # POST /reports
  # POST /reports.xml
  def create
    authorize! :create, Report
    @report = Report.new(params[:report])
    @report.user_id = current_user.id

    # Since they can only see their own reports this isn't absolutely required, but we hve this as anextra layer of precaution    
    # Verify user can view this report. Must be in his product
    unless @report.product.nil?
      authorize_product!(@report.product)
    end
    
    respond_to do |format|
      if @report.save
        format.html { redirect_to(@report, :notice => 'Report was successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /reports/1
  # PUT /reports/1.xml
  def update
    authorize! :update, Report
    @report = Report.find(params[:id])

    # Since they can only see their own reports this isn't absolutely required, but we hve this as anextra layer of precaution    
    # Verify user can view this report. Must be in his product
    unless @report.product.nil?
      authorize_product!(@report.product)
      # Verify that if they change the product, it is changed to a product they have access to.
      authorize_product!(Product.find(params[:report][:product_id]))
    end 
        
    respond_to do |format|
      if @report.update_attributes(params[:report])
        format.html { redirect_to(@report, :notice => 'Report was successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /reports/1
  # DELETE /reports/1.xml
  def destroy
    authorize! :destroy, Report
    @report = Report.find(params[:id])
    
    if @report.user_id == current_user.id
      @report.destroy
      redirect_to reports_url, :flash => { :notice => "Report has been deleted." }
    else
      redirect_to reports_url, :flash => { :warning => "You do not have access to this report." }
    end
  end
  
  # GET /reports/run/1
  def run
    authorize! :read, Report
    @report = Report.find(params[:id])
    
    # Since they can only see their own reports this isn't absolutely required, but we hve this as anextra layer of precaution    
    # Verify user can view this report. Must be in his product
    unless @report.product.nil?
      authorize_product!(@report.product)
    end
    
    # It is easy to generate errors on reports (wrong values etc.)
    # It is imperative that we trap all errors
    begin    
      if @report.user_id == current_user.id
        if @report.report_type == "System Status"
          @num_products = Product.all.count
          @num_test_cases = TestCase.all.count
          @num_categories = Category.all.count
          @num_results = Result.all.count
        
        elsif @report.report_type == "Release Current State"
          @tests_total= 0
          @tests_passed = 0
          @tests_failed = 0
          @tests_blocked = 0
          assignments = Assignment.where(:product_id => @report.product_id, :version_id => @report.version_id)
          assignments.each do |assignment|
            @tests_total += assignment.results.count
            @tests_passed += Result.where(:assignment_id => assignment.id, :result => "Passed" ).count
            @tests_failed += Result.where(:assignment_id => assignment.id, :result => "Failed" ).count
            @tests_blocked += Result.where(:assignment_id => assignment.id, :result => "blocked" ).count
          end
          @not_run = @tests_total - @tests_passed - @tests_failed - @tests_blocked
        
        elsif @report.report_type == "Release Progress - Daily"
          # Set the minimum start date if not set
          if (@report.start_date == nil or @report.start_date == "")
            minimum_date = Result.where( :assignment_id => Assignment.where(:product_id => @report.product_id, :version_id => @report.version_id) ).minimum('executed_at')
            if minimum_date == nil
              @report.start_date = Date.today - 1
            else
              # The result is a time item. Must convert to date or will search will happen on every millisecond
              @report.start_date = minimum_date.to_date
            end
          end
          # Set the end date to today if not set
          if (@report.end_date == nil or @report.end_date == "")
            @report.end_date = Date.today
          end
        
        elsif @report.report_type == "Release Current State - By User"
          # We find a list of all assignments related to this product/version and group by user id and save task numbers
          assignment_ids = Assignment.where(:product_id => @report.product_id, :version_id => @report.version_id).joins(:task).select('tasks.user_id').group("tasks.user_id").collect(&:user_id)
          # Using the list of task ids we collect the list of user ids
          user_ids = Task.where(:assignment_id => assignment_ids).collect(&:user_id)
          # using the user IDs, we find the users
          @users = User.find(user_ids)
          
        # ADDITIONAL REPORTS GO HERE
        end
        render
      else
        redirect_to reports_url, :flash => { :warning => "You do not have access to this report." }
      end
    # On error, return to report page with warning message
    rescue
      redirect_to report_path(@report), :flash => { :warning => "There was an error generating the report. Please check the reports settings." }
    end
  end 
  
  # reports/update_version_select/1
  # Get the versions for the current product
  # Then render the small versions drop down partial
  def update_version_select        
    versions = Version.where(:product_id => params[:id]).order(:version) unless params[:id].blank?
    
    # Since they can only see their own reports this isn't absolutely required, but we hve this as anextra layer of precaution    
    # Verify user can view this report. Must be in his product
    authorize_product!( Product.find(params[:id]) )
    
    render :partial => "versions", :locals => { :versions => versions }
  end
end
