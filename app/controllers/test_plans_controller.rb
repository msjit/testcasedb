class TestPlansController < ApplicationController
  # GET /test_plans
  # GET /test_plans.xml
  def index
    # The index function is now a bit more complicated.
    # The initial page lists all available products
    # Opening the products should show a lis of test plans for the product
    authorize! :read, TestPlan
    
    # New test case is used by ability in view
    # see bug... https://github.com/ryanb/cancan/issues/523
    @test_plan = TestPlan.new
    
    @products = current_user.products.order('name')
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /test_plans/1
  # GET /test_plans/1.xml
  def show
    @test_plan = TestPlan.find(params[:id])
    @comment = Comment.new(:test_plan_id => @test_plan.id, :comment => 'Enter a new comment')
    authorize! :read, @test_plan
    
    # Verify user can view this test plan. Must be in his product
    authorize_product!(@test_plan.product)
    
    # Find the parent test case ID
    parent_id = view_context.find_test_plan_parent_id(@test_plan)
  
    # Find the list of related test case versions
    @test_plans = TestPlan.where( "id = ? OR parent_id = ?", parent_id, parent_id ).where("id <> ?", @test_plan.id)
    
    respond_to do |format|
      format.html # show.html.erb
      format.pdf do
        pdf = PlanPdf.new(@test_plan, view_context)
        send_data pdf.render, :filename => "plan_#{@test_plan.id}.pdf",
                              :type => "application/pdf",
                              :disposition => "inline"
      end
      format.rtf do
        send_data generate_rtf(@test_plan), :filename => "plan_#{@test_plan.id}.rtf",
                              :type => "text/richtext",
                              :disposition => "inline"
      end
    end
  end

  # GET /test_plans/new
  # GET /test_plans/new.xml
  def new
    @test_plan = TestPlan.new
    # @test_cases = TestCase.find(:all)
    @products = current_user.products.order('name')
    authorize! :create, @test_plan

    # Make a list of all applicable custom fields and add to the test case item
    custom_fields = CustomField.where(:item_type => 'test_plan', :active => true)
    custom_fields.each do |custom_field|
      @test_plan.custom_items.build(:custom_field_id => custom_field.id)
    end
    
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /test_plans/1/edit
  def edit
    @test_plan = TestPlan.find(params[:id])
    @comment = Comment.new(:test_plan_id => @test_plan.id, :comment => 'Enter a new comment')
    
    # Verify user can view this test plan. Must be in his product
    authorize_product!(@test_plan.product)
    
    # If editing after assignment allowed or it is not assigned, start edit
    if (Setting.value('Allow Test Plan Edit After Assignment') == true) or (Assignment.where(:test_plan_id => @test_plan.id).count < 1)
      # @test_cases = TestCase.find(:all)
      @products = current_user.products.order('name')
      @plan_id = @test_plan.id
      authorize! :update, @test_plan
      
      # We need to make sure that all custom fields exist on this item. If not, we add them.
      # Find all applicable custom fields
      custom_fields = CustomField.where(:item_type => 'test_plan', :active => true)
      custom_fields.each do |custom_field|
        # If an entry for the current field doesn't exist, add it.
        if @test_plan.custom_items.where(:custom_field_id => custom_field.id).first == nil
          @test_plan.custom_items.build(:custom_field_id => custom_field.id)
        end
      end    
    #otherwise redirect to view page with warning
    else
      redirect_to @test_plan, :flash => {:warning => 'This test plan can not be edited. The plan has been assigned and editing assigned plans is disabled in the settings.'}
    end
  end

  # POST /test_plans
  # POST /test_plans.xml
  def create
    @test_plan = TestPlan.new(params[:test_plan])
    @comment = Comment.new(:test_plan_id => @test_plan.id, :comment => 'Enter a new comment')
    authorize! :create, @test_plan
    
    # Verify user can view this test plan. Must be in his product
    authorize_product!(@test_plan.product)
    
    # Set the created and modified by fields
    @test_plan.created_by = current_user
    @test_plan.modified_by = current_user
    
    respond_to do |format|
      if @test_plan.save
        # Create item in log history
        # Action type based on value from en.yaml
        History.create(:test_plan_id => @test_plan.id, :action => 1, :user_id => current_user.id)
        
        # Redirect based on button. IF they clicked SAve and Add Test cases, go to edit view
        # Otherwise, load show page
        if params[:commit] == "Save and Add Test Cases"
          format.html { redirect_to(edit_test_plan_path(@test_plan), :notice => 'Test plan was successfully created. Please add cases.') }
        else
          format.html { redirect_to(@test_plan, :notice => 'Test plan was successfully created.') }
        end
      # If there was an error, return to the new page
      else      
        @products = Product.find(:all, :order => "name")
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /test_plans/1
  # PUT /test_plans/1.xml
  def update
    @test_plan = TestPlan.find(params[:id])
    @comment = Comment.new(:test_plan_id => @test_plan.id, :comment => 'Enter a new comment')
    authorize! :update, @test_plan
    
    # Verify user can view this test plan. Must be in his product
    authorize_product!(@test_plan.product)
    # Verify that if they change the product, it is changed to a product they have access to.
    authorize_product!(Product.find(params[:test_plan][:product_id]))
    
    # Set the created and modified by fields
    @test_plan.modified_by = current_user
    
    # The list of of test case IDs are provided in order
    # Form is c=A&c=B&c=C...
    # We strip the first two chars then split values.
    # For each test case, we update the order number on Plan release
    # We only do the update if there were changes. There are no changes
    # when only removes or no changes made
    if params['selectedCaseOrder'] != ""
      orderNum = 1
      params['selectedCaseOrder'][2..-1].split('&c=').each do |id|
        plan_case = PlanCase.where(:test_case_id => id, :test_plan_id => @test_plan.id).first
        plan_case.case_order = orderNum
        plan_case.save
        orderNum += 1
      end
    end
    
    respond_to do |format|
      if @test_plan.update_attributes(params[:test_plan])
      #if @test_plan.save
        # Create item in log history
        # Action type based on value from en.yaml
        History.create(:test_plan_id => @test_plan.id, :action => 2, :user_id => current_user.id)
        format.html { redirect_to(@test_plan, :notice => 'Test plan was successfully updated.') }
      else
        @products = Product.find(:all, :order => "name")
        @plan_id = @test_plan.id
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /test_plans/1
  # DELETE /test_plans/1.xml
  def destroy
    @test_plan = TestPlan.find(params[:id])
    authorize! :destroy, @test_plan
    
    # Verify user can view this test plan. Must be in his product
    authorize_product!(@test_plan.product)
    
    if ( Assignment.where(:test_plan_id => @test_plan.id).count > 0 )
	    redirect_to test_plans_url, :flash => {:warning => 'Can not delete. Test plan has already been assigned for testing.' }
    else
      @test_plan.destroy

      # Create item in log history
      # Action type based on value from en.yaml
      History.create(:test_plan_id => @test_plan.id, :action => 3, :user_id => current_user.id)

      respond_to do |format|
        format.html { redirect_to(test_plans_path, :notice => 'Test plan was successfully deleted.') }
      end
    end
  end
  
  # GET /test_plans/copy/1
  def copy
    # begin 
      original_test_plan = TestPlan.find( params[:id] )
      
      # Verify user can view this test case. Must be in his product
      authorize_product!(original_test_plan.product)
      
      @test_plan = original_test_plan.duplicate_plan
      
      redirect_to edit_test_plan_path(@test_plan), :notice => "Test plan copied successfully"
    # rescue
    #   redirect_to test_plans_path, :flash => {:warning => 'There was an error copying the test plan.'}
    # end
  end
  
  # GET /test_plans/search/
  def search
    authorize! :read, TestPlan
    # This is used for the simple search function.
    # Note that this currently utlizes the search module that is contained within the model.
    if params[:search]
      # find(:all, :conditions => ['name LIKE ?', "%#{search}%"])
      @test_plans = TestPlan.where(:product_id => current_user.products).where('name LIKE ?', "%#{params[:search]}%")
    else
      @test_plans = TestPlan.where(:product_id => current_user.products)
    end
  end

  # get /test_plans/create_new_version/:id
  def create_new_version
    begin 
      original_test_plan = TestPlan.find( params[:id] )
      
      # Verify user can view this test plan. Must be in his product
      authorize_product!(original_test_plan.product)
      
      # Find the parent test case ID
      parent_id = view_context.find_test_plan_parent_id(original_test_plan)
    
      # Find the current max version for this parent id
      max_version = TestPlan.where( "id = ? OR parent_id = ?", parent_id, parent_id ).maximum(:version)
  
      # clone the test case
      @test_plan = original_test_plan.dup
      # Remember to increate the version value
      @test_plan.version = max_version + 1
      @test_plan.parent_id = parent_id
      if @test_plan.save      
        # Make a clone of each step for this test case
        original_test_plan.plan_cases.each do |plan_case|
          new_plan_case = plan_case.dup
          new_plan_case.test_plan_id = @test_plan.id
          new_plan_case.save
        end
      
        # Mark the earlier test case as deprecated
        original_test_plan.deprecated = true
        original_test_plan.save
      
        redirect_to @test_plan, :notice => "Test plan versioned successfully"
      else
        redirect_to test_plans_path, :flash => {:warning => 'There was an error generating the new version.'}
      end
    rescue
      redirect_to test_plans_path, :flash => {:warning => 'There was an error generating the new version.'}
    end
  end

  # GET /test_plans/:plan_id/add_case/:id
  # Call on test plan form to add a case to the selected case module
  # Done this way to calculate product name, category path
  def add_test_case
    # Find the case then load the JS
    @test_case = TestCase.find(params[:id])
    
    # Verify user can view this test plan. Must be in his product
    authorize_product!(@test_case.product)
    
    # We need to pass this on. Plan ID is required for figuring out if a case is already included
    # in a test plan
    @plan_id = params[:plan_id]
    
    # Add the test case to the test plan
    test_plan = TestPlan.find(@plan_id)
    test_plan.test_cases << @test_case
    
    respond_to do |format|
      format.js
    end
  end

  # GET /test_plans/:plan_id/remove_case/:id
  # Call on test plan form to remove case from the selected case module
  # Done this way to calculate product name, category path
  # And actually remove item
  def remove_test_case
    # Find the case then load the JS
    @test_case = TestCase.find(params[:id])
    
    # We need to pass this on. Plan ID is required for figuring out if a case is already included
    # in a test plan
    @plan_id = params[:plan_id]
    
    # Remove the test case from the test plan
    test_plan = TestPlan.find(@plan_id)
    test_plan.test_cases.delete @test_case
    
    respond_to do |format|
      format.js
    end
  end

  # GET /test_plans/list/:product_id
  def list
    # This function takes a product ID and returns a list of test plans
    #  JS is returned.

    # This new item is simple used to test if the user can create test plans
    # There is a bug in cancan that prevents ?can TestPlan from working
    # https://github.com/ryanb/cancan/issues/523
    @test_plan = TestPlan.new

    # Product ID is required for the JS
    @product_id = params[:product_id]
    
    # Verify user can view this test plan. Must be in his product
    authorize_product!(Product.find(@product_id))
      
    # Generate a list of the test plans for the product
    @test_plans = TestPlan.where(:product_id => @product_id)

    # First we insert the underline  
    #@newDivs= "<div class='rectangle' style='display: block'></div>"
  
    #if testplans.empty?
    #  @newDivs += '<div class=\"treeNoData\">Product does not have any test plans</div>'
    #else
    #  @newDivs += '<div class=\"treeNode\"><table class=\"treeTable\"'
    #  @newDivs += '<tr><th>Name</th><th>Description</th><th></th><th></th><th></th></tr>'

    #  testplans.each do |testplan|
    #    testPlanLink = '<a href=\"' + test_plan_path(testplan) + '\">' + testplan.name + '</a>'
    #    editLink = '<a href=\"' + edit_test_plan_path(testplan) + '\">Edit</a>'
    #    @newDivs +=  '<tr><td>' + testPlanLink + '</td><td>' + testplan.description + '</td><td>' + editLink + '</td></tr>'
    #  end
    #  @newDivs += '</table></div>'
    #end
  
    respond_to do |format|
      format.js
    end
  end
  
  # GET /test_plans/list/:product_id
  def list_categories
    # This function takes a product ID and returns a list of categories
    # JS returned.
    @categories = Category.find_all_by_product_id(params[:product_id], :order => "name")
    
    # We need to pass this on. Plan ID is required for figuring out if a case is already included
    # in a test plan
    @plan_id = params[:plan_id]
    
    # It seems unneccessary to get the product as it is related to the categories
    # however, if there are no categories, we still need to know which product we're deling with 
    # so we retrieve the product for the display
    @product = Product.find(params[:product_id])

    # Verify user can view this test plan. Must be in his product
    authorize_product!(@product)
    
    respond_to do |format|
      format.js
    end
  end

  # GET /test_plans/list_children/:category_id
  def list_category_children
    # This function takes a category ID and returns a list of sub-categories and test cases
    # JS is returned.
    # Pass @category_id to the js view so it knows which div to add code to
    @category_id = params[:category_id]

    # We need to pass this on. Plan ID is required for figuring out if a case is already included
    # in a test plan
    @plan_id = params[:plan_id]
    
    # Find all of the sub categories for this sub-category
    @categories = Category.find(@category_id).categories(:order => "name")
    
    # Find all of the test cases for this category
    @testcases = TestCase.where(:category_id => @category_id)

    # Verify user can view this test case. Must be in his product
    authorize_product!(Category.find(@category_id).generate_product)
      
    respond_to do |format|
      format.js
    end
  end
  
  private
  
  def generate_rtf(test_plan)
    colours = [RTF::Colour.new(0, 0, 0),
               RTF::Colour.new(255, 255, 255),
               RTF::Colour.new(100, 100, 100)]

    # Create the used styles.
    styles                           = {}
    styles['CS_TITLE']                = RTF::CharacterStyle.new
    styles['CS_TITLE'].bold           = true
    styles['CS_TITLE'].font_size      = 36
    styles['CS_BOLD']                = RTF::CharacterStyle.new
    styles['CS_BOLD'].bold           = true
    styles['CS_HEADER']                = RTF::CharacterStyle.new
    styles['CS_HEADER'].bold           = true
    styles['CS_HEADER'].font_size      = 28
    styles['CS_TABLE_HEADER']          = RTF::CharacterStyle.new
    styles['CS_TABLE_HEADER'].foreground = colours[1]
    styles['PS_NORMAL']                = RTF::ParagraphStyle.new
    styles['PS_NORMAL'].space_after    = 300
    styles['PS_TITLE']                 = RTF::ParagraphStyle.new
    styles['PS_TITLE'].space_before    = 6000
    styles['PS_TITLE'].space_after     = 300
    styles['PS_HEADER']                = RTF::ParagraphStyle.new
    styles['PS_HEADER'].space_before   = 100
    styles['PS_HEADER'].space_after    = 300
    
    # Create the document
    document = RTF::Document.new(RTF::Font.new(RTF::Font::ROMAN, 'Arial'))

    # Create the title page
    document.paragraph(styles['PS_TITLE']) do |p1|
      p1.apply(styles['CS_TITLE']) << 'Test Plan: ' + test_plan.name
    end
    document.page_break()
    
    # Create the test case list page
    document.paragraph(styles['PS_HEADER']) do |p1|
      p1.apply(styles['CS_HEADER']) << 'Test Plan Details'
    end
    
    # List test cases page
    document.paragraph(styles['NORMAL']) do |p|
      p.apply(styles['CS_BOLD']) << 'Title: '
      p <<  test_plan.name
      p.line_break
      p.apply(styles['CS_BOLD']) << 'Description: '
      p <<  test_plan.description
      p.line_break
      p.apply(styles['CS_BOLD']) << 'Version: '
      p <<  test_plan.version.to_s
      p.line_break
      p.apply(styles['CS_BOLD']) << 'Product: '
      p <<  test_plan.product.name
      p.line_break
    end

     # Test Case Header
     document.paragraph(styles['PS_HEADER']) do |p1|
       p1.apply(styles['CS_HEADER']) << 'Test Cases'
     end
    
     # Create table of test cases
     table    = document.table(test_plan.test_cases.count + 1, 5, 1750, 1750, 1750, 1050, 3000 )
     table.border_width = 5
     table[0][0].shading_colour = colours[2]
     table[0][0].apply(styles['CS_TABLE_HEADER']) << 'Name'
     table[0][1].shading_colour = colours[2]
     table[0][1].apply(styles['CS_TABLE_HEADER']) << 'Product'
     table[0][2].shading_colour = colours[2]
     table[0][2].apply(styles['CS_TABLE_HEADER']) << 'Category'
     table[0][3].shading_colour = colours[2]
     table[0][3].apply(styles['CS_TABLE_HEADER']) << 'Version'
     table[0][4].shading_colour = colours[2]
     table[0][4].apply(styles['CS_TABLE_HEADER']) << 'Description'

     i = 1
     test_plan.test_cases.order("case_order").each do | test_case|
       table[i][0] << test_case.name
       table[i][1] << test_case.product.name
       table[i][2] << test_case.category.name
       table[i][3] << test_case.version.to_s
       table[i][4] << test_case.description
      
       i = i + 1
     end

    document.line_break
    # END OF TEST CASE TABLE

    test_plan.test_cases.order("case_order").each do | test_case|
      # IMportant. The page break start the test case.
      # this is because, RTF fails to render properly if the last item in the document is a page break
      # If it is at the end, there is a page break after the last comment.
      document.page_break
      document.paragraph(styles['NORMAL']) do |p|
        p.apply(styles['CS_HEADER']) << 'Test Case: ' + test_case.name
        p.line_break
        p.apply(styles['CS_BOLD']) << 'Description: '
        p <<  test_case.description
        p.line_break
        p.apply(styles['CS_BOLD']) << 'Version: '
        p <<  test_case.version.to_s
        p.line_break
        p.apply(styles['CS_BOLD']) << 'Product: '
        p <<  test_case.product.name
        p.line_break
        p.line_break
       
        if test_case.steps.count == 0
          p << 'There are no recorded steps for this test case.'
        end
      end
      
      if test_case.steps.count > 0
        table1 = document.table(test_case.steps.count + 1, 3, 600, 4000, 4000 )
        table1.border_width = 5
        table1[0][0].shading_colour = colours[2]
        table1[0][0].apply(styles['CS_TABLE_HEADER']) << 'Step'
        table1[0][1].shading_colour = colours[2]
        table1[0][1].apply(styles['CS_TABLE_HEADER']) << 'Action'
        table1[0][2].shading_colour = colours[2]
        table1[0][2].apply(styles['CS_TABLE_HEADER']) << 'Expected Result'
        i = 1
        test_case.steps.each do |step|
          table1[i][0] << i.to_s
          table1[i][1] << step.action
          if step.result == nil
            table1[i][2] << ' '
          else
            table1[i][2] << step.result
          end
          i = i + 1
        end
        table1.to_rtf
      end
    end
   
    document.to_rtf
  end
end