class TestCasesController < ApplicationController
  # GET /test_cases
  # GET /test_cases.xml
  def index
    # The index function is now a bit more complicated.
    # The initial page lists all available products
    # Opening the products should show a lis of categories for that product
    authorize! :read, TestCase
    
    # New test case is used by ability in view
    # see bug... https://github.com/ryanb/cancan/issues/523
    @test_case = TestCase.new
    
    @products = current_user.products.order('name')
    respond_to do |format|
      format.html # index.html.erb
      format.csv do
        # Test case IDs are sent as params
        # ex:   :1234 => "1"
        # We looked for all numbered items as test cases and export them
        tc_ids = []
        params.each do |key,value|
          if key.to_i != 0 and value == '1'
            tc_ids << key.to_i
          end
        end
           
        send_data generate_csv(TestCase.find(tc_ids)), :filename => "test_case.csv",
                              :type => "text/csv",
                              :disposition => "inline"
      end
    end
  end

  # GET /test_cases/1
  # GET /test_cases/1.xml
  def show
    @test_case = TestCase.find(params[:id])
    authorize! :read, @test_case
    
    # Verify user can view this test case. Must be in his product
    authorize_product!(@test_case.product)
    
    # Find the parent test case ID
    parent_id = view_context.find_test_case_parent_id(@test_case)
  
    # Find the list of related test case versions
    @test_cases = TestCase.where( "id = ? OR parent_id = ?", parent_id, parent_id ).where("id <> ?", @test_case.id)
    
    # For the monnent section
    @comment = Comment.new(:test_case_id => @test_case.id, :comment => 'Enter a new comment')

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /test_cases/new
  # GET /test_cases/new/:category_id
  def new
    @test_case = TestCase.new
    
    # Have one step ready to go
    @test_case.steps.build(:step_number => 1)
    # Have one target ready to go
    @test_case.test_case_targets.build

    # if this page was invoked with a category_id param it means the user clicked a link
    # that should auto fill the category (and product drop down) for them
    if params[:category_id]
      # To make this work, we set the test case category_id, we figure out which
      # product this category is a sibling of and we produce the list of categories
      # for this product
      @test_case.category_id = params[:category_id]
      @test_case.product_id = get_product_id_from_category_id(@test_case.category_id)
      # The category list for the current product (one of which is selected)
      @categories = category_list(@test_case.product_id, nil)
    end

    authorize! :create, @test_case
    
    # Make a list of all applicable custom fields and add to the test case item
    custom_fields = CustomField.where(:item_type => 'test_case', :active => true)
    custom_fields.each do |custom_field|
      @test_case.custom_items.build(:custom_field_id => custom_field.id)
    end

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /test_cases/1/edit
  def edit
    # View requires the test cases
    @test_case = TestCase.find(params[:id])
    @comment = Comment.new(:test_case_id => @test_case.id, :comment => 'Enter a new comment')
    
    # If editing after executed allowed or it has not been executed, allow edit
    if (Setting.value('Allow Test Case Edit After Execution') == true) or (Result.where("test_case_id = ? AND result is not null", @test_case.id).count < 1)
          
      # The category list for the current product (one of which is selected)
      @categories = category_list(@test_case.product_id, nil)
      
      authorize! :update, @test_case
      
      # Verify user can view this test case. Must be in his product
      authorize_product!(@test_case.product)
      
      # If there are no existing steps, add one now
      if @test_case.steps.count == 0
        @test_case.steps.build(:step_number => 1)
      end
      
     # If there are no existing targets, add one now
      if @test_case.test_case_targets.count == 0
        @test_case.test_case_targets.build
      end
      
      # We need to make sure that all custom fields exist on this item. If not, we add them.
      # Find all applicable custom fields
      custom_fields = CustomField.where(:item_type => 'test_case', :active => true)
      custom_fields.each do |custom_field|
        # If an entry for the current field doesn't exist, add it.
        if @test_case.custom_items.where(:custom_field_id => custom_field.id).first == nil
          @test_case.custom_items.build(:custom_field_id => custom_field.id)
        end
      end
      
    #otherwise, redirect to show page with warning
    else
      redirect_to @test_case, :flash => {:warning => 'This test case can not be edited. The case has been executed and editing executed cases is disabled in the settings.'}
    end
  end

  # POST /test_cases
  # POST /test_cases.xml
  def create
    @test_case = TestCase.new(params[:test_case])
    @comment = Comment.new(:test_case_id => @test_case.id, :comment => 'Enter a new comment')
    
    authorize! :create, @test_case
    
    # Verify user can view this test case. Must be in his product
    authorize_product!(@test_case.product)
    
    # Set the created and modified by fields
    @test_case.created_by = current_user
    @test_case.modified_by = current_user
    
    respond_to do |format|
      # If save is successfull
      if @test_case.save
        
        # Create item in log history
        # Action type based on value from en.yaml
        History.create(:test_case_id => @test_case.id, :action => 1, :user_id => current_user.id)
        
        # If this is save and add step load edit page for steps to be added
        if params[:commit] == "Save and Create Additional"
          format.html { redirect_to(new_test_case_with_category_path(@test_case.category_id), :notice => 'Test case was successfully created. Please create another test case.') }
        # Else, just load the show page
        else 
          format.html { redirect_to(@test_case, :notice => 'Test case was successfully created.') }
        end 
        
      # if the save fails
      else
        
        if @test_case.product_id
          # If a product ID was selected, we need to pre-populate the list of categories
          @categories = category_list(@test_case.product_id, nil)
          @categories.insert(0, ["Select a category", ""])
        end
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /test_cases/1
  # PUT /test_cases/1.xml
  def update
    @test_case = TestCase.find(params[:id])
    authorize! :update, @test_case
    
    # Verify user can view this test case. Must be in his product
    authorize_product!(@test_case.product)
    # Verify that if they change the product, it is changed to a product they have access to.
    authorize_product!(Product.find(params[:test_case][:product_id]))
    
    @comment = Comment.new(:test_case_id => @test_case.id, :comment => 'Enter a new comment')
    
    # Set the modified by user field
    @test_case.modified_by = current_user
    
    respond_to do |format|
      if @test_case.update_attributes(params[:test_case])
        # Create item in log history
        # Action type based on value from en.yaml
        History.create(:test_case_id => @test_case.id, :action => 2, :user_id => current_user.id)
        format.html { redirect_to(@test_case, :notice => 'Test case was successfully updated.') }
      else
        
        if @test_case.product_id
          # If a product ID was selected, we need to pre-populate the list of categories
          @categories = category_list(@test_case.product_id, nil)
          @categories.insert(0, ["Select a category", ""])
        end
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /test_cases/1
  # DELETE /test_cases/1.xml
  def destroy
    @test_case = TestCase.find(params[:id])
    authorize! :destroy, @test_case
    
    # Verify user can view this test case. Must be in his product
    authorize_product!(@test_case.product)
        
    if ( PlanCase.where(:test_case_id => @test_case.id).count > 0 )
	    redirect_to test_cases_url, :flash => {:warning => 'Can not delete. Test case is assigned to a test plan.' }
    elsif ( Result.where(:test_case_id => @test_case.id).count > 0 )
	    redirect_to test_cases_url, :flash => {:warning => 'Can not delete. Test case already has results.' }
    else
      @test_case.destroy

      # Create item in log history
      # Action type based on value from en.yaml
      History.create(:test_case_id => @test_case.id, :action => 3, :user_id => current_user.id)

      respond_to do |format|
        format.html { redirect_to(test_cases_path, :notice => 'Test case was successfully deleted.') }
      end
    end
  end
  
  # GET /test_cases/search/
  def search
    authorize! :read, TestCase
    # This is used for the simple search function.
    # Note that this currently utlizes the search module that is contained within the model.
    if params[:search]
      # find(:all, :conditions => ['name LIKE ?', "%#{search}%"])
      @test_cases = TestCase.where(:product_id => current_user.products).where('name LIKE ?', "%#{params[:search]}%")
    else
      @test_cases = TestCase.where(:product_id => current_user.products)
    end
  end
  
  # GET /test_cases/import/
  def import
    @test_case = TestCase.new
  end
  
  # POST /test_cases/import/
  def import_create
    # We need to be capture the myriad of issues that can occur with open an excel spreadsheet
    begin
      # open the spread sheet and prepare variables
      uploaded_io = params[:test_case][:upload]
      # book = Spreadsheet.open '/Users/marc/Desktop/test_cases.xls'
      book = Spreadsheet.open uploaded_io.open
    
      sheet1 = book.worksheet 0
      errors = false
      @test_cases = []
    
      # Verify a valid product and category were selected
      if (Product.where(:id => params[:test_case][:product_id]).first == nil) or (Category.where(:id => params[:test_case][:category_id]).first == nil)
        errors = true
        # An error has occurred. Redirect to import page
        @test_case = TestCase.new
        redirect_to import_new_test_case_path, :flash => {:warning => 'Please select a valid product and category then try again.'}
      # Only analyse if there is a valid xls header
      elsif  check_for_header( sheet1.row(0) ) == true
        # Before we continue on, we must validate that the product is valid and the user didn't try to manually swap the product
        authorize_product!(Product.where(:id => params[:test_case][:product_id]).first)
        
        # Predefine these variable so they are not block local variables
        test_case = TestCase.new
        step_number = 0
        i = 0
      
        sheet1.each(1) do |row|
          # We need to test for errors for each row. If there has already been an error
          # Parsing when there has already been an issue may generate a nilClass error.
          if errors == false
            if defines_test_case( row )
              # Create the test case
              test_case = generate_case_from_row( row )
              @test_cases << test_case
              step_number = 1
              i += 1
            elsif defines_step( row )
              step_number += 1
              @test_cases[i - 1].steps << generate_step_from_row( row, test_case.id, step_number )
            else
              errors = true
              # An error has occurred. Redirect to import page
              @test_case = TestCase.new
              redirect_to import_new_test_case_path, :flash => {:warning => 'There was an error on line ' + (row.idx + 1).to_s + '. Please try again.'}
            end
          end
        end  
      
        # If there were no errors, save all cases and steps
        if errors == false
          @test_cases.each do |test_case|
            test_case.save
          end
        end
    
      # If there was no valid header in XLS
      else
        errors = true
        # XLS file does not have a valid header
        @test_case = TestCase.new
        redirect_to import_new_test_case_path, :flash => {:warning => 'The XLS file is missing a valid header.'}
      end 
    # If something went wrong return to upload page with warning 
    rescue
      redirect_to import_new_test_case_path, :flash => {:warning => 'There was an issue opening and parsing the file. Please retry with a valid XLS file.'}
    end
  end
  
  # get /test_cases/create_new_version/:id
  # Create a new version copies a test case, increase the version
  # and marks the previous case as deprecated
  def create_new_version
    begin 
      original_test_case = TestCase.find( params[:id] )
    
      # Verify user can view this test case. Must be in his product
      authorize_product!(original_test_case.product)
      
      # Find the parent test case ID
      parent_id = view_context.find_test_case_parent_id(original_test_case)
    
      # Find the current max version for this parent id
      max_version = TestCase.where( "id = ? OR parent_id = ?", parent_id, parent_id ).maximum(:version)
  
      # clone the test case
      @test_case = original_test_case.dup
      # Remember to increate the version value
      @test_case.version = max_version + 1
      @test_case.parent_id = parent_id
      @test_case.save
      
      # Make a clone of each step for this test case
      original_test_case.steps.each do |step|
        new_step = step.dup
        new_step.test_case_id = @test_case.id
        new_step.save
      end
      
      # Mark the earlier test case as deprecated
      original_test_case.deprecated = true
      original_test_case.save
      
      redirect_to @test_case, :notice => "New version created successfully"
    rescue
      redirect_to test_cases_path, :flash => {:warning => 'There was an error generating the new version.'}
    end
  end  
  
  # get /test_cases/copy/:id
  # copies the test case.
  # starts as new version with no parent
  def copy
    begin 
      original_test_case = TestCase.find( params[:id] )
      
      # Verify user can view this test case. Must be in his product
      authorize_product!(original_test_case.product)
      
      # clone the test case
      @test_case = original_test_case.duplicate_case
      
      redirect_to edit_test_case_path(@test_case), :notice => "Test case copied successfully"
    rescue
      redirect_to test_cases_path, :flash => {:warning => 'There was an error copying the test case.'}
    end
  end
  
  # GET /test_cases/list/:product_id
  def list
    authorize! :read, TestCase
    
    # This new item is simple used to test if the user can create test cases
    # There is a bug in cancan that prevents ?can TestCase from working
    # https://github.com/ryanb/cancan/issues/523
    @test_case = TestCase.new
    
    # This function takes a product ID and returns a list of categories
    # either JS or HTML is returned.
    @categories = Category.find_all_by_product_id(params[:product_id], :order => "name")
    
    # It seems unneccessary to get the product as it is related to the categories
    # however, if there are no categories, we still need to know which product we're deling with 
    # so we retrieve the product for the display
    @product = Product.find(params[:product_id])

    # Verify user can view this test case. Must be in his product
    authorize_product!(@product)
    
    respond_to do |format|
      format.js
    end
  end

  # GET /test_cases/list_children/:category_id
  def list_children
    authorize! :read, TestCase
    
    # This new item is simple used to test if the user can create test cases
    # There is a bug in cancan that prevents ?can TestCase from working
    # https://github.com/ryanb/cancan/issues/523
    @test_case = TestCase.new
    
    # This function takes a category ID and returns a list of sub-categories and test cases
    # either JS or HTML is returned.
    # Pass @category_id to the js view so it knows which div to add code to
    @category_id = params[:category_id]
    
    # Find all of the sub categories for this sub-category
    @categories = Category.find(@category_id).categories(:order => "name")
    
    # Find all of the test cases for this category
    @testcases = TestCase.where(:category_id => @category_id).includes(:tags)

    # Verify user can view this test case. Must be in his product
    authorize_product!(Category.find(@category_id).generate_product)
    
    respond_to do |format|
      format.js
    end
  end
  
  # test_cases/update_category_select/1
  # Get the category for the current proj
  # Then render the small versions drop down partial
  def update_category_select
    authorize! :read, TestCase
    
    unless params[:id].blank?  
      @categories = category_list(params[:id], nil) 
    end
    render :partial => "categories"
  end
  
  # category_list takes a product_id and builds a list of categories
  # The final result is an an array with 3 &nbsp; spaces to indent each level
  # The funtion is recursive and uses the product_id to start
  # Should be called as category_list(x, nil)
  def category_list(product_id, category)
    authorize! :read, TestCase
    
    if product_id
      categories = Category.where(:product_id => product_id).order(:name).collect {|c| [c.name, c.id]}
    else
      categories = Category.where(:category_id => category[1]).order(:name).collect {|c| [c.name, c.id]}
    end

    # Make a duplicate as we need to navigate the main item
    duplicate_categories = categories.dup
    cat_length = categories.length
    i = 0

    categories.each do |category|
      # Recursively find sub-categories
      sub_categories = category_list(nil, category)
      # If not a blank list, add it in
      unless sub_categories == []
        # Add the white space for this level
        (0...sub_categories.size).each do |j|
          sub_categories[j][0] = "&nbsp;&nbsp;&nbsp;".html_safe + sub_categories[j][0].to_s.html_safe
        end
        # Add the items to the list one by one to the end of the list as we do not know total size
        sub_categories.each do |sub_category|
          duplicate_categories.insert(-cat_length + i, sub_category)
        end
      end
      i += 1
    end

    return duplicate_categories
  end
  
  private
  
  # Take a row from the spreadsheet and check if it is
  # the header row
  # return true if it is, false otherwise
  def check_for_header(row)
    if row[0] == 'Test Case Name'
      if row[1] == 'Description'
        if row[2] == 'Type'
          if row[3] == 'Step'
            if row[4] == 'Result'
              return true
            end
          end
        end
      end
    end
    
    return false
  end
  
  # return true if this line defines a test case
  # returns false otherwise
  def defines_test_case( row )
    if row[0] != nil
      if row[1] != nil
        if row[2] != nil
          if row[3] != nil
            # I used to check if there was a result. that is not a requirement for the line to describe a test case
            return true
          end
        end
      end
    end
    
    return false
  end
  
  # returns true if this is a step
  # Is a step if there is an action optionally a result only.
  def defines_step( row )
    if row[3] != nil
      if row[0] == nil
        if row[1] == nil
          if row[2] == nil
            return true
          end
        end
      end
    end
  
    return false
  end  
  
  # Takes a spreadsheet row
  # returns a TestCase item
  def generate_case_from_row( row )
    test_case = TestCase.new
    test_case.name = row[0]
    test_case.description = row[1]
    test_case.test_type_id = TestType.where(:name => row[2]).first.id
    test_case.product_id = params[:test_case][:product_id]
    test_case.category_id = params[:test_case][:category_id]
    
    # Always set the test case status to 0 (this is draft see en.yml :item_status)
    test_case.status = 0
    
    # Set the created and modified by fields to the logged in user
    test_case.created_by = current_user
    test_case.modified_by = current_user
    
    # Generate the first step based on this row
    test_case.steps << generate_step_from_row(row, test_case.id, 1)
    
    return test_case
  end
  
  # Takes a spreadsheet row
  # returns a Step
  def generate_step_from_row( row, test_case_id, step_number )
    # Append a step
    step = Step.new
    step.action = row[3]
    step.result = row[4]
    step.test_case_id = test_case_id
    step.step_number = step_number
    
    return step
  end
  
  # Takes an array of test cases and exports them as a CSV
  def generate_csv(test_cases)
    require 'csv'
    tc_csv = CSV.generate do |csv|
      # header row
      csv << ["Name", "Product", "Cateogry", "Version", "Description", "Test Type", "Deprecated", "Created By", "Modified By", "Action", "Result"]

      # data rows
      test_cases.each do |tc|
        csv << [tc.name, tc.product.name, tc.category.name, tc.version.to_s, tc.description, tc.test_type ? tc.test_type.name : '' , tc.deprecated ? "Yes" : "No", tc.created_by ? tc.created_by.first_name + ' ' + tc.created_by.last_name : ' ', tc.modified_by ? tc.modified_by.first_name + ' ' + tc.modified_by.last_name : ' ', '', '']
        
        tc.steps.each do |step|
          csv << ['', '', '', '', '', '', '', '', '', step.action, step.result]
        end
      end
    end
    
    tc_csv
  end
  
end
