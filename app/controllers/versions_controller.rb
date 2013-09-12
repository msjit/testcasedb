class VersionsController < ApplicationController
  # The sortable method requires these
  helper_method :sort_column, :sort_direction
  
  # GET /versions
  # GET /versions.xml
  def index
    authorize! :read, Version
    # There is a filter option on the version page We need to provide results based on filter.
    
    # Was a product search filter provided
    if (params[:product] && Product.all.collect(&:id).include?(params[:product][:id].to_i))
      # If yes, remember item for page load. And verify product access
      
      # Verify user can view version for this product. Must be in his product
      authorize_product!(Product.find(params[:product][:id]))
      
      @selected_product_id = params[:product][:id]
      @versions = Version.includes(:product).where(:product_id => @selected_product_id).order(sort_column + " " + sort_direction).page(params[:page]).per(20)
    else
      @versions = Version.includes(:product).where(:product_id => current_user.products).order(sort_column + " " + sort_direction).page(params[:page]).per(20)
    end
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /versions/1
  # GET /versions/1.xml
  def show
    @version = Version.find(params[:id])
    authorize! :show, @version
    
    # Verify user can view this version. Must be in his product
    authorize_product!(@version.product)
    
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /versions/new
  # GET /versions/new.xml
  def new
    @version = Version.new
    authorize! :create, @version
    
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /versions/1/edit
  def edit
    @version = Version.find(params[:id])
    authorize! :update, @version
    
    # Verify user can view this version. Must be in his product
    authorize_product!(@version.product)
  end

  # POST /versions
  # POST /versions.xml
  def create
    @version = Version.new(params[:version])    
    authorize! :create, @version
    
    # Verify user can view this version. Must be in his product
    authorize_product!(@version.product)
    
    respond_to do |format|
      # If saved successfully
      if @version.save
        # If it is save and new
        if params[:commit] == "Save and Create Additional"
          format.html { redirect_to( new_version_path, :notice => 'Version was successfully created. Please create another.') }
         # If it is just save, show the new user
        else
          format.html { redirect_to(@version, :notice => 'Version was successfully created.') }
        end
      # If the save fails
      else
        @products_select = Product.find(:all).collect {|p| [ p.name, p.id ]}
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /versions/1
  # PUT /versions/1.xml
  def update
    @version = Version.find(params[:id])
    authorize! :update, @version
    
    # Verify user can view this version. Must be in his product
    authorize_product!(@version.product)
    # Verify that if they change the product, it is changed to a product they have access to.
    authorize_product!(Product.find(params[:version][:product_id]))
    
    respond_to do |format|
      if @version.update_attributes(params[:version])
        format.html { redirect_to(@version, :notice => 'Version was successfully updated.') }
      else
        @products_select = Product.find(:all).collect {|p| [ p.name, p.id ]}
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /versions/1
  # DELETE /versions/1.xml
  def destroy
    @version = Version.find(params[:id])
    authorize! :destroy, @version
    
    # Verify user can view this version. Must be in his product
    authorize_product!(@version.product)
    
    # Only destroy a version if it is in use.
    if ( Assignment.where(:version_id => @version.id).count > 0 )
	    redirect_to(versions_url, :flash => {:warning => "Can not delete version. Version is in use."} )
	  elsif ( Report.where(:version_id => @version.id).count > 0 )
	    redirect_to(versions_url, :flash => {:warning => "Can not delete version. Version is in use."} )
	  else
      @version.destroy
    
      respond_to do |format|
        format.html { redirect_to(versions_url) }
      end
    end
  end
  
  private
  
  # Functions for sorting columns
  # Among other things, these prevent SQL injection
  # Set asc and name as default values
  def sort_column
    # Version.column_names.include?(params[:sort]) ? params[:sort] : "version"
    %w[version description products.name].include?(params[:sort]) ? params[:sort] : "version"
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
