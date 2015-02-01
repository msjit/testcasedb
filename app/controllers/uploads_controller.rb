class UploadsController < ApplicationController
  SEND_FILE_METHOD = :default

  def create
    authorize! :create, Upload    
    
    if params[:test_case_id]
  	  @test_case = TestCase.find(params[:test_case_id])
      @upload = @test_case.uploads.build(params[:upload])

      respond_to do |format|
        if @upload.save
          # History.create(:test_case_id => @test_case.id, :action => 7, :user_id => current_user.id)
          format.html { redirect_to( @test_case, :notice => 'Upload was successfully added.') }
          format.js
        else
          format.html { render :action => "new" }
          format.js { render "create_error"}
        end
      end
    elsif params[:result_id]
  	  @result = Result.find(params[:result_id])
      @upload = @result.uploads.build(params[:upload])

      respond_to do |format|
        if @upload.save
          #History.create(:test_plan_id => @test_plan.id, :action => 7, :user_id => current_user.id)
         format.html { redirect_to edit_result_path(@result) , :notice => 'Upload was successfully added.' }
         format.js
       else
         format.html { render :action => "new" }
         format.js { render "create_error"}
        end
      end
    end
  end

  def show
    @upload = Upload.find(params[:id])
  end
 
  def update
    @upload = Upload.find(params[:id])
    authorize! :update, @upload
    
    respond_to do |format|
      if @upload.update_attributes(params[:upload])        
        format.html { redirect_to(@upload, :notice => 'Product was successfully updated.') }
        format.json { respond_with_bip(@upload) }
      else
        format.html { render :action => "edit" }
        format.json { respond_with_bip(@upload) }
      end
    end
  end
   
  def destroy
    @upload = Upload.find(params[:id])
    authorize! :destroy, Upload
    @upload_id = @upload.id
    
    respond_to do |format|    
      # We only allow attachments that belong to test cases to be deleted
      # Attachments belong to test cases cannot be deleted
      if @upload.test_case != nil
        test_case = @upload.test_case
        @upload.destroy

        format.html { redirect_to test_case, :notice => 'Attachement has been deleted.' }
        format.js
      elsif @upload.result != nil
        result = @upload.result
        @upload.destroy
      
        format.html { redirect_to result, :notice => 'Attachement has been deleted.' }
        format.js
      end
    end
  end
  
  def download
    authorize! :read, Upload
    
    head(:not_found) and return if (upload = Upload.find_by_id(params[:id])).nil?
    head(:forbidden) and return unless upload.downloadable?(current_user)

    path = upload.upload.path(params[:style])
    head(:bad_request) and return unless File.exist?(path) && params[:format].to_s == File.extname(path).gsub(/^\.+/, '')

    # send_file_options = { :type => File.mime_type?(path) }
    send_file_options = { :type => 'application/octet-stream', :filename => upload.upload_file_name }
    
    case SEND_FILE_METHOD
      when :apache then send_file_options[:x_sendfile] = true
      when :nginx then head(:x_accel_redirect => path.gsub(Rails.root, ''), :content_type => send_file_options[:type]) and return
    end

    send_file(path, send_file_options)
  end
  
  # GET uploads/:id/executable
  def executable
    upload = Upload.find(params[:id])
    authorize! :execute, Upload
    
    @upload_id = upload.id
    
    File.chmod(0744, upload.upload.path)
    
    # Make an uplaod file executable
    # do nothing for now  
    respond_to do |format| 
      format.html { redirect_to upload.test_case, :notice => 'Attachement is now executable.' }
      format.js 
    end
  end
end
