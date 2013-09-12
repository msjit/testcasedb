class TestTypesController < ApplicationController
  # GET /test_types
  # GET /test_types.xml
  def index
    authorize! :read, TestType
    @test_types = TestType.all
    
    # Create for bug with cancan and multi name classes
    @test_type = TestType.new
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /test_types/1
  # GET /test_types/1.xml
  def show
    @test_type = TestType.find(params[:id])
    authorize! :read, @test_type
    
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /test_types/new
  # GET /test_types/new.xml
  def new
    @test_type = TestType.new
    authorize! :create, @test_type
    
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /test_types/1/edit
  def edit
    @test_type = TestType.find(params[:id])
    authorize! :update, @test_type
  end

  # POST /test_types
  # POST /test_types.xml
  def create
    @test_type = TestType.new(params[:test_type])
    authorize! :create, @test_type
    
    respond_to do |format|
      # If changes can be saved
      if @test_type.save
        if params[:commit] == "Save and Create Additional"
          format.html { redirect_to( new_test_type_path, :notice => 'Test type was successfully created. Please create another.') }
         # If it is just save, show the new user
        else
          format.html { redirect_to(@test_type, :notice => 'Test type was successfully created.') }
        end
      # otherwise redirect to form
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /test_types/1
  # PUT /test_types/1.xml
  def update
    @test_type = TestType.find(params[:id])
    authorize! :update, @test_type
    
    respond_to do |format|
      if @test_type.update_attributes(params[:test_type])
        format.html { redirect_to(@test_type, :notice => 'Test type was successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /test_types/1
  # DELETE /test_types/1.xml
  def destroy
    @test_type = TestType.find(params[:id])
    authorize! :destroy, @test_type
    
	  if ( TestCase.where(:test_type_id => @test_type.id).count > 0 )
	    redirect_to(test_types_url, :flash => {:warning => "Can not delete test type as it is in use"} )
	  elsif ( TestType.count == 1 )
	    redirect_to(test_types_url, :flash => {:warning => "Not deleted. There must be at least one test type"} )
	  else
      @test_type.destroy
      respond_to do |format|
	      format.html { redirect_to(test_types_url) }
	    end
	  end
  end
end
