class WebapiController < ApplicationController
  def run
    # Make sure only XML user can use this
    authorize! :create, Webapi
    
    # We assume no error and no details message
    @success = "No"
    @error ="No"
    
    # Make a hash of the xml parameters
    xml_params = Hash.from_xml(request.body.read)

    # Check that the generic required params are included in request
    # If details are returned, it means there was an error
    @details = check_xml_params( xml_params )
    
    # If details has an error, ignore rest of command
    # otherwise try to run command
    if @details != nil
      @error = "Yes"
    # Try to run the command
    else
      case xml_params['api_request']['command']
      when "CheckVersion"
        result_hash = check_version(xml_params)
      when "CreateVersion"
        result_hash = create_version(xml_params)
      when "CreateAssignment"
        result_hash = create_assignment(xml_params)
      when "SetResult"
        result_hash = set_result(xml_params)
      when "GetResult"
        result_hash = get_result(xml_params)
      else 
        result_hash ={"success" => "No", "details" => "Command not recognized. Please see documentation.", "error" => "Yes"} 
      end
      
      # Take the hash and break out the values to the main variables
      # If we made it this far, these variables should have been in their default state until now
      @error = result_hash["error"]
      @success = result_hash["success"]
      @details = result_hash["details"]
    end
    
    respond_to do |format|
      format.xml {render :layout => false}
    end
  end

  private
  
  # Takes the xml param hash as argument
  # verifies required items included in the params hash
  # returns error if required items are missing 
  def check_xml_params(xml_params)
    details = nil
    
    if xml_params['api_request'] == nil
      details = "Request does not include the api_request item. Please see documentation."
    elsif xml_params['api_request']['command'] == nil
      details = "Request does not include a command. Please see documentation."
    elsif xml_params['api_request']['value'] == nil
      details = "Request does not include a value. Please see documentation."
    end
    
    return details
  end
  
  # Run the create assignment command
  # Return a hash of success, error and details
  def create_assignment(xml_params)
    # Set the returned hash to default values
    result_hash ={"success" => "No", "details" => "", "error" => "No"}
    
    # Perform the search in the DB to check values. Expected source from XML
    # option1 = Product Name
    # option2 = Product Version
    # option3 = Test Plan Version
    # value = Test Plan ID
    
    # Search for the product first
    product = Product.where(:name => xml_params['api_request']['option1'] ).first
    
    # If the product had a match we search for the version
    if product != nil
      version = Version.where(:version => xml_params['api_request']['option2'], :product_id => product.id ).first
      
      # If the version exists we search for the test plan
      if version != nil
        test_plan = TestPlan.where(:id => xml_params['api_request']['value'], :version => xml_params['api_request']['option3'], :product_id => product.id ).first
        
        # If the test plan exists, create the assignment
        if test_plan != nil
          assignment = Assignment.new(:product_id => product.id, :version_id => version.id, :test_plan_id => test_plan.id)
          saveResult = assignment.save
          
          # Only create results if assignment create is successful
          if saveResult
            # For each test case in the test plan, we must make a copy of
            # the test case in the result DB. 
            assignment.test_plan.test_cases.each do |testCase|
              assignment.results.create(:test_case_id => testCase.id)
            end
            
            # Set the success message. The details provides the asignment ID
            result_hash["success"] = "Yes"
            result_hash["details"] = assignment.id.to_s
          else
            result_hash["error"] = "Yes"
            result_hash["details"] = "Failed to create assignment."
          end
        else
          result_hash["error"] = "Yes"
          result_hash["details"] = "Assignment not created. Test Plan not found."
        end
      else
        result_hash["error"] = "Yes"
        result_hash["details"] = "Assignment not created. Version not found."
      end
    else
      result_hash["error"] = "Yes"
      result_hash["details"] = "Assignment not created. Product not found."
    end  
    
    return result_hash
  end
  
  
  # Run the check version command
  # Return a hash of success, error and details
  def check_version(xml_params)
    # Set the returned hash to default values
    result_hash ={"success" => "No", "details" => "", "error" => "No"}
    
    # Perform the search in the DB to check values. Expected source from XML
    # option1 = Product Name
    # value = Version name
    
    # Search for the product first (we  don't do a nested query right away to check if product passes)
    if Product.where(:name => xml_params['api_request']['option1'] ).first != nil
      # If the product had a match we check for the version
      if Version.where(:version => xml_params['api_request']['value'], :product_id => Product.where(:name => xml_params['api_request']['option1']).first.id ) != []
        result_hash["success"] = "Yes"
        result_hash["details"] = "Version found."
      # Set message if product found, but not version. This is considered no success and no error
      else
        result_hash["details"] = " Version not found for this product."
      end
    # Set message for product not found
    else
      result_hash["error"] = "Yes"
      result_hash["details"] = "Invalid product. Version not found."
    end
    
    return result_hash
  end

  # Run the create version command
  # Return a hash of success, error and details
  def create_version(xml_params)
    # Set the returned hash to default values
    result_hash ={"success" => "No", "details" => "", "error" => "No"}
    
    # Perform the create version in the DB to check values. Expected source from XML
    # option1 = Product Name
    # value = Version name
    
    # First verify that the product exists
    if Product.where(:name => xml_params['api_request']['option1'] ).first != nil
      # Verify that the version doesn't exist
      if Version.where(:version => xml_params['api_request']['value'], :product_id => Product.where(:name => xml_params['api_request']['option1']).first.id ) != []
        result_hash["error"] = "Yes"
        result_hash["details"] = "Error. The version already exists for this product."
      # If it doesn't exist, create the version now
      else
        version = Version.new(:version => xml_params['api_request']['value'], :product_id => Product.where(:name => xml_params['api_request']['option1']).first.id )
        if version.save
          result_hash["details"] = "Version created successfully."
          result_hash["success"] = "Yes"
        else
          result_hash["details"] = "Error creating version."
          result_hash["error"] = "Yes"
        end
      end
    # Set message for product not found
    else
      result_hash["error"] = "Yes"
      result_hash["details"] = "Invalid product. Unable to create version."
    end
    
    return result_hash
  end

  # Run the get result command
  # Return a hash of success, error and details
  # Details will contain the result
  def get_result(xml_params)
    # Set the returned hash to default values
    result_hash ={"success" => "No", "details" => "", "error" => "No"}
    
    # Perform the create version in the DB to check values. Expected source from XML
    # option1 = asignment_id
    # value = test_case_id
    
    # Find the result entry
    result = Result.where(:assignment_id => xml_params['api_request']['option1'], :test_case_id => xml_params['api_request']['value'] ).first
    
    # If the result is valid, update the result and save
    if result != nil
      result_hash["success"] = "Yes"
      result_hash["details"] = result.result
    else
      result_hash["error"] = "Yes"
      result_hash["details"] = "Could not find result."
    end

    return result_hash
  end
  
  # Run the set result command
  # Return a hash of success, error and details
  def set_result(xml_params)
    # Set the returned hash to default values
    result_hash ={"success" => "No", "details" => "", "error" => "No"}
    
    # Perform the create version in the DB to check values. Expected source from XML
    # option1 = asignment_id
    # option2 = test_case_id
    # option3 = bugs  # This is optional format x,y,z same, as application
    # value = result
    
    test_state = xml_params['api_request']['value']
    # Check that value is a valid Result
    if test_state == "Passed" or test_state == "Failed" or test_state =="Blocked"
      # Find the result entry
      result = Result.where(:assignment_id => xml_params['api_request']['option1'], :test_case_id => xml_params['api_request']['option2'], :result => nil ).first
      
      # If the result is valid, update the result and save
      if result != nil
        result.result = test_state
        result.save
        result_hash["success"] = "Yes"
        result_hash["details"] = "Result state updated."
      else
        result_hash["error"] = "Yes"
        result_hash["details"] = "Invalid result or result already set. Please consult the documentation."
      end
      
    else
      result_hash["error"] = "Yes"
      result_hash["details"] = "Invalid value in request. Please consult the documentation."
    end

    return result_hash
  end

end