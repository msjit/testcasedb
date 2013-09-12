class DevicesController < ApplicationController
  # GET /devices
  # GET /devices.xml
  def index
    authorize! :read, Device
    @devices = Device.all

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /devices/1
  # GET /devices/1.xml
  def show
    @device = Device.find(params[:id])
    authorize! :read, @device
    
    @schedules = @device.schedules.order('start_time')
    @schedules.each do |schedule|
      schedule.start_time = schedule.start_time + Time.current.utc_offset
    end
    
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /devices/new
  # GET /devices/new.xml
  def new
    @device = Device.new
    authorize! :create, @device

    # Make a list of all applicable custom fields and add to the test case item
    custom_fields = CustomField.where(:item_type => 'device', :active => true)
    custom_fields.each do |custom_field|
      @device.custom_items.build(:custom_field_id => custom_field.id)
    end
    
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /devices/1/edit
  def edit
    @device = Device.find(params[:id])
    authorize! :update, @device
    
    # We need to make sure that all custom fields exist on this item. If not, we add them.
    # Find all applicable custom fields
    custom_fields = CustomField.where(:item_type => 'device', :active => true)
    custom_fields.each do |custom_field|
      # If an entry for the current field doesn't exist, add it.
      if @device.custom_items.where(:custom_field_id => custom_field.id).first == nil
        @device.custom_items.build(:custom_field_id => custom_field.id)
      end
    end
  end

  # POST /devices
  # POST /devices.xml
  def create
    @device = Device.new(params[:device])
    authorize! :create, @device
    
    respond_to do |format|
      if @device.save
        format.html { redirect_to(@device, :notice => 'Device was successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /devices/1
  # PUT /devices/1.xml
  def update
    @device = Device.find(params[:id])
    authorize! :update, @device
    
    respond_to do |format|
      if @device.update_attributes(params[:device])
        format.html { redirect_to(@device, :notice => 'Device was successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /devices/1
  # DELETE /devices/1.xml
  def destroy
    @device = Device.find(params[:id])
    authorize! :destroy, @product
    
    @device.destroy

    respond_to do |format|
      format.html { redirect_to(devices_url) }
    end
  end
end
