class AssignmentsController < ApplicationController
  # The sortable method requires these
  helper_method :sort_column, :sort_direction
  
  # GET /assignments
  # GET /assignments.xml
  def index
    authorize! :read, Assignment
    authorize! :read, Result
    # There is a filter option on the assignments page We need to provide results based on filter.
    
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

  # GET /assignments/1
  # GET /assignments/1.xml
  def show
    authorize! :read, Assignment
    @assignment = Assignment.find(params[:id])
    
    # Verify user can view items for this product. Must be in his product
    authorize_product!(@assignment.product)
    
    # Get the results sorted in order based on test plan
    # @results = Result.where(:assignment_id => @assignment.id).
    #   joins('left join assignments on (results.assignment_id = assignments.id)').
    #   joins('left join plan_cases on (plan_cases.test_case_id = results.test_case_id AND plan_cases.test_plan_id = assignments.test_plan_id)').
    #   order('case_order')
    @results = Result.where(:assignment_id => @assignment.id).order('id').includes(:test_case)
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /assignments/new
  # GET /assignments/new.xml
  def new
    authorize! :create, Assignment
    @assignment = Assignment.new
    @assignment.task = Task.new
    
    # This is for the auto created task
    @users_select = User.all_users_ordered
        
    @products_select = current_user.products
    
    # Test Plans have an ssign link. To do this they submit test_plan_id as a param.
    # If test  plan ID is included, we set the test plan and product for the assignment.
    # This is provided as a convenience
    if params[:test_plan_id]
      @assignment.product_id = TestPlan.where(:id => params[:test_plan_id]).first.product_id
      @assignment.test_plan_id = params[:test_plan_id].to_i
      
      # Verify user can view items for this product. Must be in his product
      authorize_product!(@assignment.product)
    elsif params[:stencil_id]
      @assignment.product_id = Stencil.where(:id => params[:stencil_id]).first.product_id
      @assignment.stencil_id = params[:stencil_id].to_i

      # Verify user can view items for this product. Must be in his product
      authorize_product!(@assignment.product)
    end
    
    #!# @versions = Version.find(:all)
    #!# @plans_select = TestPlan.find(:all).collect {|p| [ p.name + " | Version " + p.version.to_s, p.id ]}

    # Make a list of all applicable custom fields and add to the result item
    custom_fields = CustomField.where(:item_type => 'assignment', :active => true)
    custom_fields.each do |custom_field|
      @assignment.custom_items.build(:custom_field_id => custom_field.id)
    end
    
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /assignments/1/edit
  def edit
    authorize! :update, Assignment
    @assignment = Assignment.find(params[:id])
    
    # Verify user can view items for this product. Must be in his product
    authorize_product!(@assignment.product)

  	# We need to make sure that all custom fields exist on this item. If not, we add them.
  	# Find all applicable custom fields
  	custom_fields = CustomField.where(:item_type => 'assignment', :active => true)
  	custom_fields.each do |custom_field|
    # If an entry for the current field doesn't exist, add it.
    	if @assignment.custom_items.where(:custom_field_id => custom_field.id).first == nil
   		   @assignment.custom_items.build(:custom_field_id => custom_field.id)
    	end
  	end
    
    # This is for the related created task
    @users_select = User.all_users_ordered
  end

  # POST /assignments
  # POST /assignments.xml
  def create
    authorize! :create, Assignment
    @assignment = Assignment.new(params[:assignment])
    
    # Verify user can view items for this product. Must be in his product
    authorize_product!(@assignment.product)
    
    # We need to catch errors iwith missing versions as it is used right away
    # If no error we prep the task
    if @assignment.version == nil
      @assignment.errors.add :version, ' can\'t be blank'
      saveResult = nil
    elsif (@assignment.test_plan == nil) and (@assignment.stencil == nil)
      @assignment.errors.add :product_id, 'Test plan or a stencil should be selected.'
      saveResult = nil
    elsif ((@assignment.test_plan != nil) and (@assignment.stencil != nil))
      @assignment.errors.add :product_id, 'Test plan or a stencil should be selected. You cannot select both.'
      saveResult = nil
    else
      # Next we decide if it is a test plan of stencil to be executed
      if @assignment.test_plan
        # Task name automatically set to Execute #plan against #version
        @assignment.task.name = "Execute " + @assignment.test_plan.name + " against " + @assignment.version.version
      else 
        # Task name automatically set to Execute #plan against #version
        @assignment.task.name = "Execute " + @assignment.stencil.name + " against " + @assignment.version.version
      end
      
      # We manually set the task type and status
      # See en.yml for explanation. This sets type to Execute assignment
      # and status to assigned
      @assignment.task.task = 4
      @assignment.task.status = 0

      saveResult = @assignment.save

      # Only add the results if save was successful. Missed this earlier and was getting blank result items
      if saveResult
        # For each test case in the test plan, we must make a copy of
        # the test case in the result DB.
        if @assignment.test_plan != nil 
          @assignment.test_plan.plan_cases.order('case_order').each do |planCase|
            @assignment.results.create(:test_case_id => planCase.test_case_id)
          end
        else
          @assignment.stencil.stencil_test_plans.each do |stencil_test_plan|
            stencil_test_plan.test_plan.plan_cases.order('case_order').each do |planCase|
              @assignment.results.create(:test_case_id => planCase.test_case_id, :device_id => stencil_test_plan.device_id )
            end
          end
        end
      end
    end

    respond_to do |format|
      if saveResult
        # Create item in log history
        # Action type based on value from en.yaml
        History.create(:assignment_id => @assignment.id, :action => 1, :user_id => current_user.id)
        @url = task_path(@assignment.task, :only_path => false)
        
        begin
          UserMailer.task_assigned(@assignment.task, @url).deliver
          
          logger.debug "Assignment created. Id is #{@assignment.id}"
          format.html { redirect_to(@assignment, :notice => 'Assignment was successfully created.') }
        rescue
          logger.debug "Assignment created. Id is #{@assignment.id}"
          format.html { redirect_to(@assignment, :warning => 'Assignment was successfully created, but email was not sent.') }
        end
      else
        # Are these the four items we need for failed create
        @users_select = User.all_users_ordered
        @products_select = Product.find(:all).collect {|p| [ p.name, p.id ]}

        logger.warn "Assignment not saved correctly}"
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /assignments/1
  # PUT /assignments/1.xml
  def update
    authorize! :update, Assignment
    @assignment = Assignment.find(params[:id])

    # Verify user can view items for this product. Must be in his product
    authorize_product!(@assignment.product)
    
    respond_to do |format|
      if @assignment.update_attributes(params[:assignment])
        # Create item in log history
        # Action type based on value from en.yaml
        History.create(:assignment_id => @assignment.id, :action => 2, :user_id => current_user.id)
        format.html { redirect_to(@assignment, :notice => 'Assignment was successfully updated.') }
      else
        # Are these the four items we need for failed create
        @users_select = User.all_users_ordered
        @products_select = Product.find(:all).collect {|p| [ p.name, p.id ]}
        #!# @versions = Version.find(:all)
        #!# @plans_select = TestPlan.find(:all).collect {|p| [ p.name + " | Version " + p.version.to_s, p.id ]}
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /assignments/1
  # DELETE /assignments/1.xml
  def destroy
    authorize! :destroy, Assignment
    @assignment = Assignment.find(params[:id])
    
    # Verify user can view items for this product. Must be in his product
    authorize_product!(@assignment.product)
    
    @assignment.destroy

    respond_to do |format|
      # Create item in log history
      # Action type based on value from en.yaml
      History.create(:assignment_id => @assignment.id, :action => 3, :user_id => current_user.id)
      format.html { redirect_to(assignments_url) }
    end
  end

  # assignments/update_version_select/1
  # Get the versions for the current product
  # Then render the small versions drop down partial
  def update_version_select
    # Verify user can view items for this product. Must be in his product
    authorize_product!( Product.find(params[:id]) )
            
    versions = Version.where(:product_id => params[:id]).order(:version) unless params[:id].blank?
    render :partial => "versions", :locals => { :versions => versions }
  end 
  
  # assignments/update_test_plan_select/1
  # Get the versions for the current product
  # Then render the small versions drop down partial
  def update_test_plan_select 
    # Verify user can view items for this product. Must be in his product
    authorize_product!( Product.find(params[:id]) )
           
    test_plans = TestPlan.where(:product_id => params[:id]).order(:name) unless params[:id].blank?
    render :partial => "test_plans", :locals => { :test_plans => test_plans }
  end
  
  # assignments/update_stencil_select/1
  # Get the stencils for the current product
  # Then render the small stencils drop down partial
  def update_stencil_select 
    # Verify user can view items for this product. Must be in his product
    authorize_product!( Product.find(params[:id]) )
           
    stencils = Stencil.where(:product_id => params[:id]).order(:name) unless params[:id].blank?
    render :partial => "stencils", :locals => { :stencils => stencils }
  end
  
  private

  # Functions for sorting columns
  # Among other things, these prevent SQL injection
  # Set asc and name as default values
  def sort_column
    # We no longer use the old way as we accept nexted query results
    # Assignment.column_names.include?(params[:sort]) ? params[:sort] : "product_id"
    %w[id products.name versions.version test_plans.name stencils.name notes].include?(params[:sort]) ? params[:sort] : "id"
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end 
end
