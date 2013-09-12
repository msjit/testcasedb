class TagsController < ApplicationController
  # GET /tags
  # GET /tags.xml
  def index
    authorize! :read, Tag
    @tags = Tag.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @tags }
    end
  end

  # GET /tags/1
  # GET /tags/1.xml
  def show
    @tag = Tag.find(params[:id])
    authorize! :read, @tag
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @tag }
    end
  end

  # GET /tags/new
  # GET /tags/new.xml
  def new
    @tag = Tag.new
    authorize! :create, @tag

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @tag }
    end
  end

  # GET /tags/1/edit
  def edit
    @tag = Tag.find(params[:id])
    authorize! :update, @tag
  end

  # POST /tags
  # POST /tags.xml
  def create
    @tag = Tag.new(params[:tag])
    authorize! :create, @tag

    respond_to do |format|
      if @tag.save
        # If this is save and create additional
        if params[:commit] == "Save and Create Additional"
          format.html { redirect_to(new_tag_path, :notice => 'Tag successfully created. Please create another tag.') }
        # Else, just load the show page
        else 
          format.html { redirect_to(@tag, :notice => 'Tag successfully created.') }
        end
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /tags/1
  # PUT /tags/1.xml
  def update
    @tag = Tag.find(params[:id])
    authorize! :update, @tag

    respond_to do |format|
      if @tag.update_attributes(params[:tag])
        format.html { redirect_to(@tag, :notice => 'Tag was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tag.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tags/1
  # DELETE /tags/1.xml
  def destroy
    @tag = Tag.find(params[:id])
    authorize! :destroy, @tag
    @tag.destroy

    respond_to do |format|
      format.html { redirect_to(tags_url) }
      format.xml  { head :ok }
    end
  end
end
