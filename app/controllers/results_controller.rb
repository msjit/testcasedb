class ResultsController < ApplicationController
  # The sortable method requires these
  helper_method :sort_column, :sort_direction
  
  # GET /results
  # GET /results.xml
  def index
    authorize! :read, Result
    # There is a filter option on the execute page We need to provide results based on filter.
    
    # What a product search filter provided
    if (params[:product] && Product.all.collect(&:id).include?(params[:product][:id].to_i))
      # If yes, remember item for page load
      @selected_product_id = params[:product][:id]
      
      # Verify user can view items for this product. Must be in his product
      authorize_product!(Product.find(@selected_product_id))
      
      # Was a version also provided?
      if (params[:version] && Version.all.collect(&:id).include?(params[:version][:id].to_i))
        # If yes, remember the version and do a query based on product and version
        # With filter, Note, even with filter we still paginate.
        @selected_version_id = params[:version][:id]
        @assignments = Assignment.includes(:product, :version, :test_plan, :stencil).where(:product_id => @selected_product_id, :version_id => @selected_version_id).
        order(sort_column + " " + sort_direction).page(params[:page]).per(20)
      else
        # there was no version, but the was a product, so we search on product and paginate
        @assignments = Assignment.includes(:product, :version, :test_plan, :stencil).where(:product_id => @selected_product_id).order(sort_column + " " + sort_direction).
        page(params[:page]).per(20)
      end
    else
      # There was no version or product, so we return all assignments and paginate
      @assignments = Assignment.includes(:product, :version, :test_plan, :stencil).where(:product_id => current_user.products).order(sort_column + " " + sort_direction).page(params[:page]).per(20)
    end
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /results/1
  # GET /results/1.xml
  def show
    authorize! :read, Result
    @result = Result.find(params[:id])

    # For results, we verify that the actual assignment product is visible
    # Verify user can view items for this product. Must be in his product
    authorize_product!(@result.assignment.product)
    
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /results/new
  # GET /results/new.xml
  def new
    authorize! :create, Result
    @result = Result.new

    # Make a list of all applicable custom fields and add to the result item
    custom_fields = CustomField.where(:item_type => 'result', :active => true)
    custom_fields.each do |custom_field|
      @result.custom_items.build(:custom_field_id => custom_field.id)
    end

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /results/1/edit
  def edit
    authorize! :update, Result
    @result = Result.find(params[:id])
    
    # For results, we verify that the actual assignment product is visible
    # Verify user can view items for this product. Must be in his product
    authorize_product!(@result.assignment.product)

  	# We need to make sure that all custom fields exist on this item. If not, we add them.
  	# Find all applicable custom fields
  	custom_fields = CustomField.where(:item_type => 'result', :active => true)
  	custom_fields.each do |custom_field|
    # If an entry for the current field doesn't exist, add it.
    	if @result.custom_items.where(:custom_field_id => custom_field.id).first == nil
   		   @result.custom_items.build(:custom_field_id => custom_field.id)
    	end
  	end

  end

  # POST /results
  # POST /results.xml
  def create
    authorize! :create, Result
    @result = Result.new(params[:result])

    # For results, we verify that the actual assignment product is visible
    # Verify user can view items for this product. Must be in his product
    authorize_product!(@result.assignment.product)
    
    respond_to do |format|
      if @result.save
        format.html { redirect_to(@result, :notice => 'Result was successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /results/1
  # PUT /results/1.xml
  def update
    authorize! :update, Result
    @result = Result.find(params[:id])
    
    # For results, we verify that the actual assignment product is visible
    # Verify user can view items for this product. Must be in his product
    authorize_product!(@result.assignment.product)
    
    # First we check if the system is configured to require bugs
    # for blocks and failures. 
    # If there is an issue we manually set an error  
    if params[:result][:result] == 'Failed'
      if Setting.value('Require Bug For Failed Result') == true
        # Verify value not blank
        if params[:result][:bugs] == ""
          @result.errors.add :bugs, '- At least one valid bug number is required for a failed test case.'
        end
      end
      if Setting.value('Require Comment For Failed Result') == true
        # Verify value not blank
        if params[:result][:note] == ""
          @result.errors.add :note, '- A note is required for a failed test case.'
        end
      end
    elsif params[:result][:result] == 'Blocked'
      if Setting.value('Require Bug For Blocked Result') == true
        if params[:result][:bugs] == ""
          @result.errors.add :bugs, '- At least one valid bug number is required for a blocked test case.'
        end
      end
      if Setting.value('Require Comment For Blocked Result') == true
        if params[:result][:note] == ""
          @result.errors.add :note, '- A note is required for a blocked test case.'
        end
      end
    elsif !params[:result][:result]
      @result.errors.add :result, '- A valid result must be entered.'
    end
    
    # If bugs is not blank and a ticketing system is set, we check that the values are valid
    if params[:result][:bugs] != ""
      if Setting.value('Ticket System') != 'none'
        # If ticket system is set, check that all bugs exist
        # need to send bug status an array of IDs so we split the comma separated list
        results = Ticket.bug_status( params[:result][:bugs].split(',') )
        if results["error"] == true
          @result.errors.add :bugs, '- At least one entered bug number could not be found in the ticket system.'
        end
      end
    end
    
    # If there is no executed_at value and we now have a result
    # Set the execution time before updating attributes
    if @result.executed_at.nil? && params[:result][:result]
      params[:result][:executed_at] = DateTime.now
    end
    
    # Note that we first check if errors were added above. If not, we try to update values
    if @result.errors.empty? && @result.update_attributes(params[:result])
      # Create item in log history
      # Action type based on value from en.yaml
      if @result.result == "Passed"
        History.create(:result_id => @result.id, :action => 4, :user_id => current_user.id)
      elsif @result.result == "Failed"
        History.create(:result_id => @result.id, :action => 5, :user_id => current_user.id)
      elsif @result.result == "Blocked"
        History.create(:result_id => @result.id, :action => 6, :user_id => current_user.id)
      end
      
      # If all of the results on an assignment now have a result, set the task to complete
      # We have a rescues as it is possible the task was not created
      # For example, assignments generated via API do not create tasks
      begin
        if Result.where("assignment_id = :assignment_id  AND result is NULL", {:assignment_id => @result.assignment_id}).count == 0
          @result.assignment.task.status = 127
          @result.assignment.task.completion_date = Date.today
          @result.assignment.task.save
        end
      rescue
        # Do nothing as task can not be found
      end
      
      # If the user wants to view the result, direct them to it
      if params[:commit] == "Save and View" 
        redirect_to(@result, :notice => 'Result was successfully updated.')
      
      # Otherwise, direct them to the next test case to execute
      # This should be reviewed at some point and improved perfomance wise
      elsif params[:commit] == "Save and Execute Next"
        # Get a list of results
        results = Result.where(:assignment_id => @result.assignment_id).order('id')
      
        # We look for current result in ordered list and then return next result
        next_found = false
        is_next = false
        result_id = nil
        results.each do |result|
          # have we already found the next result
          if next_found == true
            # do nothing
          # If this is the next one, set it
          elsif is_next == true
            result_id = result.id
            next_found = true
            is_next = false
          # is this the current result. If so, we want the next one
          elsif result.id == @result.id
            is_next = true
          end
        end
        
        # if next result found, run it in edit mode
        if next_found == true
          @result = Result.find(result_id)
          redirect_to( edit_result_path(@result), :notice => 'Result saved' )
        # Otherwise, return to the assignment overview
        else
          redirect_to( @result.assignment, :notice => 'Result saved')
        end
      end
    else
      # Due to the method that we validate all fields in this update module
      # These values are not passed on if there is an error
      # We pass them back to the user
      @result.result = params[:result][:result]
      @result.note = params[:result][:note]
      @result.bugs = params[:result][:bugs]
      flash[:warn] = "There was an error saving the result. See below for more details."
      render :action => "edit"
    end

  end

  # DELETE /results/1
  # DELETE /results/1.xml
  def destroy
    authorize! :destroy, Result
    @result = Result.find(params[:id])
    
    # For results, we verify that the actual assignment product is visible
    # Verify user can view items for this product. Must be in his product
    authorize_product!(@result.assignment.product)
    
    @result.destroy

    respond_to do |format|
      format.html { redirect_to(results_url) }
    end
  end
  
  # GET /results/:id/comare
  def compare
    authorize! :read, Result
    @result = Result.find(params[:id])
    
    # For results, we verify that the actual assignment product is visible
    # Verify user can view items for this product. Must be in his product
    authorize_product!(@result.assignment.product)
    
    # Find all related results
    # Related results are results for the identical test case that were run in the same test plan
    # We do not compare to test cases that were run as part of another test plan
    stats = ResultStatistic.where(:result_id => Result.where(:test_case_id => @result.test_case_id, :assignment_id => Assignment.where(:test_plan_id => @result.assignment.test_plan_id))).order('result_id')
    
    @result_ids = []

    # stats.each do |stat| 
    #   unless @result_ids.include? stat.result_id
    #     @result_ids << stat.result_id
    #   end
    #   
    #   if @stats[stat.name]
    #     @stats[stat.name] << stat.mean
    #   else
    #     @stats[stat.name] = [stat.mean]
    #   end
    #   end

    # Build array of result_ids and result names
    # We need these so we can build an ordered 2d dictionary
    @result_ids = []
    result_names = [] 
    stats.each do |stat|
      unless @result_ids.include? stat.result_id
        @result_ids << stat.result_id
      end
      unless result_names.include? stat.name
        result_names << stat.name
      end
    end

    # Build the 2d dictionary using the names and IDs
    # All values set to 0. This way if no result fills that square
    # it appears as 0 in the graph
    @stats = {}
    result_names.each do |name|
      @stats[name] = ActiveSupport::OrderedHash.new
      @result_ids.each do |id|
        @stats[name][id] = 0
      end
    end 
    
    # Fill the values in to the array
    stats.each do |stat|      
      @stats[stat.name][stat.result_id] = stat.mean
    end
    
    respond_to do |format|
      format.html # show.html.erb
    end
  end
  
  private
    
  # Functions for sorting columns
  # Among other things, these prevent SQL injection
  # Set asc and name as default values
  def sort_column
    # Assignment.column_names.include?(params[:sort]) ? params[:sort] : "products_id"
    %w[id products.name versions.version test_plans.name stencils.name].include?(params[:sort]) ? params[:sort] : "products.name"
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
