class CustomFieldsController < ApplicationController
  # GET /custom_fields
  # GET /custom_fields.xml
  def index
    authorize! :read, CustomField
    @custom_fields = CustomField.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @custom_fields }
    end
  end

  # GET /custom_fields/1
  # GET /custom_fields/1.xml
  def show
    @custom_field = CustomField.find(params[:id])
    authorize! :read, @custom_field
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @custom_field }
    end
  end

  # GET /custom_fields/new
  # GET /custom_fields/new.xml
  def new
    @custom_field = CustomField.new
    authorize! :create, @custom_field
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @custom_field }
    end
  end

  # GET /custom_fields/1/edit
  def edit
    @custom_field = CustomField.find(params[:id])
    authorize! :update, @custom_field
  end

  # POST /custom_fields
  # POST /custom_fields.xml
  def create
    @custom_field = CustomField.new(params[:custom_field])
    authorize! :create, @custom_field
    
    respond_to do |format|
      if @custom_field.save
        format.html { redirect_to(@custom_field, :notice => 'Custom field was successfully created.') }
        format.xml  { render :xml => @custom_field, :status => :created, :location => @custom_field }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @custom_field.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /custom_fields/1
  # PUT /custom_fields/1.xml
  def update
    @custom_field = CustomField.find(params[:id])
    authorize! :update, @custom_field
    
    respond_to do |format|
      if @custom_field.update_attributes(params[:custom_field])
        format.html { redirect_to(@custom_field, :notice => 'Custom field was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @custom_field.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /custom_fields/1
  # DELETE /custom_fields/1.xml
  def destroy
    @custom_field = CustomField.find(params[:id])
    authorize! :update, @custom_field
    
	@custom_field.destroy
    respond_to do |format|
      format.html { redirect_to(custom_fields_url) }
	end
  end
end
