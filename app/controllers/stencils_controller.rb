class StencilsController < ApplicationController
  # The sortable method requires these
  helper_method :sort_column, :sort_direction
  
  # GET /stencils
  # GET /stencils.xml
  def index
    authorize! :read, Stencil
    
    @stencils = Stencil.includes(:product).where(:product_id => current_user.products).order(sort_column + " " + sort_direction).page(params[:page]).per(20)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /stencils/1
  # GET /stencils/1.xml
  def show
    @stencil = Stencil.find(params[:id])
    authorize! :read, Stencil
    
    # Verify user can view this stencil. Must be in his product
    authorize_product!(@stencil.product)
    
    # Find the parent test case ID
    parent_id = view_context.find_stencil_parent_id(@stencil)
    
    # Find the list of related test case versions
    @stencils = Stencil.where( "id = ? OR parent_id = ?", parent_id, parent_id ).where("id <> ?", @stencil.id)
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @stencil }
    end
  end

  # GET /stencils/new
  # GET /stencils/new.xml
  def new
    @stencil = Stencil.new
    authorize! :create, Stencil
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @stencil }
    end
  end

  # GET /stencils/1/edit
  def edit
    @stencil = Stencil.find(params[:id])
    authorize! :update, Stencil
    
    if (Setting.value('Allow Test Plan Edit After Assignment') == true) or (Assignment.where(:stencil_id => @stencil.id).count < 1)
      # Verify user can view this test plan. Must be in his product
      authorize_product!(@stencil.product)
      
      render
    else
      redirect_to @stencil, :flash => {:warning => 'This stencil can not be edited. The stencil has been assigned and editing assigned stencils is disabled in the settings.'}
    end
  end

  # POST /stencils
  # POST /stencils.xml
  def create
    @stencil = Stencil.new(params[:stencil])
    authorize! :create, Stencil
    
    # Verify user can view this test plan. Must be in his product
    authorize_product!(@stencil.product)
    
    # Set the created and modified by fields
    @stencil.created_by = current_user
    @stencil.modified_by = current_user
    
    respond_to do |format|
      if @stencil.save
        # Create item in log history
        # Action type based on value from en.yaml
        History.create(:stencil_id => @stencil.id, :action => 1, :user_id => current_user.id)
        
        # Redirect based on button. IF they clicked SAve and Add Test cases, go to edit view
        # Otherwise, load show page
        if params[:commit] == "Save and Add Test Plans"
          format.html { redirect_to(edit_stencil_path(@stencil), :notice => 'Stencil was successfully created. Please add test plans.') }
        else
          format.html { redirect_to(@stencil, :notice => 'Stencil was successfully created.') }
        end
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @stencil.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /stencils/1
  # PUT /stencils/1.xml
  def update
    @stencil = Stencil.find(params[:id])
    authorize! :update, Stencil
    
    # Verify user can view this test plan. Must be in his product
    authorize_product!(@stencil.product)
    
    @stencil.modified_by = current_user
    
    respond_to do |format|
      if @stencil.update_attributes(params[:stencil])
        # Create item in log history
        # Action type based on value from en.yaml
        History.create(:stencil_id => @stencil.id, :action => 2, :user_id => current_user.id)
        
        format.html { redirect_to(@stencil, :notice => 'Stencil was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @stencil.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /stencils/1
  # DELETE /stencils/1.xml
  def destroy
    @stencil = Stencil.find(params[:id])
    authorize! :destroy, Stencil
    
    # Verify user can view this test plan. Must be in his product
    authorize_product!(@stencil.product)
    
    if ( Assignment.where(:stencil_id => @stencil.id).count > 0 )
	    redirect_to stencils_url, :flash => {:warning => 'Can not delete. Stencil has already been assigned for testing.' }
    else
      @stencil.destroy

      # Create item in log history
      # Action type based on value from en.yaml
      History.create(:stencil_id => @stencil.id, :action => 3, :user_id => current_user.id)

      respond_to do |format|
        format.html { redirect_to(stencils_path, :notice => 'Stencil was successfully deleted.') }
      end
    end
  end
  
  # get /stencils/create_new_version/:id
  def create_new_version
    begin 
      original_stencil = Stencil.find( params[:id] )
      
      # Verify user can view this test plan. Must be in his product
      authorize_product!(original_stencil.product)
      
      # Find the parent test case ID
      parent_id = view_context.find_stencil_parent_id(original_stencil)
    
      # Find the current max version for this parent id
      max_version = Stencil.where( "id = ? OR parent_id = ?", parent_id, parent_id ).maximum(:version)
  
      # clone the test case
      @stencil = original_stencil.dup
      # Remember to increate the version value
      @stencil.version = max_version + 1
      @stencil.parent_id = parent_id
      if @stencil.save      
        # Make a clone of each stencil_test_plan
        original_stencil.stencil_test_plans.each do |stencil_test_plan|
          new_stencil_test_plan = stencil_test_plan.dup
          new_stencil_test_plan.stencil_id = @stencil.id
          new_stencil_test_plan.save
        end
      
        # Mark the earlier test case as deprecated
        original_stencil.deprecated = true
        original_stencil.save
      
        redirect_to @stencil, :notice => "Stencil versioned successfully"
      else
        redirect_to stencils_path, :flash => {:warning => 'There was an error generating the new version.'}
      end
    rescue
      redirect_to stencils_path, :flash => {:warning => 'There was an error generating the new version.'}
    end
  end
  
  
  # stencils/update_test_plan_select/1
  # Get the test plans for the current product
  # Then render the drop downs
  def update_test_plan_select 
    # Verify user can view items for this product. Must be in his product
    authorize_product!( Product.find(params[:id]) )

    test_plans = TestPlan.where(:product_id => params[:id]).order(:name) unless params[:id].blank?
    render :partial => "test_plans", :locals => { :test_plans => test_plans }
  end
  
  private
  
  # Functions for sorting columns
  # Among other things, these prevent SQL injection
  # Set asc and name as default values
  def sort_column
    # Stencil.column_names.include?(params[:sort]) ? params[:sort] : "id"
    %w[id products.name name version].include?(params[:sort]) ? params[:sort] : "id"
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
