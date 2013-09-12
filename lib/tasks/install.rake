namespace :install do
  desc "Base install"
  task :base => :environment do
    if Setting.count > 0 or User.count > 0 or Product.count > 0 or Version.count > 0
      puts "Script could not be run." 
    else
      Setting.find_or_create_by_name(:name => 'SystemID', :value => (0...12).map{ ('A'..'Z').to_a[rand(26)] }.join, :description => 'System ID String.')
      Setting.find_or_create_by_name(:name => 'Ticket System', :value => 'none', :description => 'The type of ticketing system to integrate with.')
      Setting.find_or_create_by_name(:name => 'Ticket System Url', :value => 'none', :description => 'The url of the ticketing system.')
      Setting.find_or_create_by_name(:name => 'Ticket System Username', :value => 'none', :description => 'The username for the the ticketing system user.')
      Setting.find_or_create_by_name(:name => 'Ticket System Password', :value => 'none', :description => 'The password for the the ticketing system user.')
      Setting.find_or_create_by_name(:name => 'Require Bug For Failed Result', :value => 'Disabled', :description => 'Require that a bug number is entered on a failed result.')
      Setting.find_or_create_by_name(:name => 'Require Comment For Failed Result', :value => 'Disabled', :description => 'Require a comment for a failed result.')
      Setting.find_or_create_by_name(:name => 'Require Bug For Blocked Result', :value => 'Disabled', :description => 'Require that a bug number is entered on a blocked result.')
      Setting.find_or_create_by_name(:name => 'Require Comment For Blocked Result', :value => 'Disabled', :description => 'Require a comment for a blocked result.')
      Setting.find_or_create_by_name(:name => 'Allow Test Case Edit After Execution', :value => 'Enabled', :description => 'Once a test case is executed, editing the test case is blocked if this is disabled. Versions can be used for changes if disabled.')
      Setting.find_or_create_by_name(:name => 'Allow Test Plan Edit After Assignment', :value => 'Enabled', :description => 'Once a test plan is assigned, editing the test plan is blocked if this is disabled. Version can be used for changes if disabled.')
      Setting.find_or_create_by_name(:name => 'Allow attachment execution', :value => 'Disabled', :description => 'To enable automation to run on the system (excluding the API), this feature must be enabled. Even with this enabled, only attachments that are marked as executable by an administrator or QA Manager will be executable.')
      Setting.find_or_create_by_name(:name => 'jMeter Host', :value => 'none', :description => 'The hostname or IP address of the jMeter host system.')
      Setting.find_or_create_by_name(:name => 'jMeter User', :value => 'none', :description => 'The username for the jMeter host.')
      Setting.find_or_create_by_name(:name => 'jMeter Password', :value => 'none', :description => 'The password for the jMeter host. Note that this will not be used if a certificate is configured for login.')
      Setting.find_or_create_by_name(:name => 'jMeter SSH Certificate', :value => 'none', :description => 'The certificate file that should be used to login to the jMeter system. This should be the full path to the file. Leave as none if you plan on using a password.')
      Setting.find_or_create_by_name(:name => 'jMeter Working Directory', :value => 'none', :description => 'The jMeter working directory on the jMeter host. jMeter should save all logs to this folder. This is where TestCaseDB will run commands from. A full path should be provided. ex. /home/jmeter/working')
      Setting.find_or_create_by_name(:name => 'jMeter Application Path', :value => 'none', :description => 'Location of the jMeter jar file on the jMeter host. Can be relative to the working directory (ex. apache-jmeter/bin/ApacheJMeter.jar) or a complete path (ex. /usr/local/apache-jmeter/bin/ApacheJMeter.jar)')
      Setting.find_or_create_by_name(:name => 'jMeter Max Execution Time', :value => '5', :description => 'The maximum execution time for a jMeter test in minutes. If the test runs longer than this time it will be marked as failed.')
      Setting.find_or_create_by_name(:name => 'Sikuli Host', :value => 'none', :description => 'The hostname or IP address of the Sikuli host system.')
      Setting.find_or_create_by_name(:name => 'Sikuli User', :value => 'none', :description => 'The username for the Sikuli host.')
      Setting.find_or_create_by_name(:name => 'Sikuli Password', :value => 'none', :description => 'The password for the Sikuli host. Note that this will not be used if a certificate is configured for login.')
      Setting.find_or_create_by_name(:name => 'Sikuli SSH Certificate', :value => 'none', :description => 'The certificate file that should be used to login to the Sikuli system. This should be the full path to the file. Leave as none if you plan on using a password.')
      Setting.find_or_create_by_name(:name => 'Sikuli Working Directory', :value => 'none', :description => 'The Sikuli working directory on the Sikuli host. Sikuli should save all logs to this folder. This is where TestCaseDB will run commands from. A full path should be provided. ex. /home/sikuli/working')
      Setting.find_or_create_by_name(:name => 'Sikuli Application Path', :value => 'none', :description => 'Location of the Sikuli start script on the Sikuli host. Can be relative to the working directory (ex. Sikuli-IDE/sikuli-ide.sh) or a complete path (ex. /home/tcdb/Sikulix.y.z/Sikuli-IDE/sikuli-ide.sh)')
      Setting.find_or_create_by_name(:name => 'Sikuli Max Execution Time', :value => '5', :description => 'The maximum execution time for a Sikuli test in minutes. If the test runs longer than this time it will be marked as failed.')    
      
      User.create(:username => 'admin', :email => 'test@testcasedb.com', :first_name => 'Admin', :last_name => 'User', :password => 'ChangeMe', :password_confirmation => 'ChangeMe', :time_zone => 'Eastern Time (US & Canada)', :role => 10, :active => true)
      TestType.find_or_create_by_name(:name => 'Manual', :description => 'For manually executed test cases.')
      TestType.find_or_create_by_name(:name => 'Automated', :description => 'For test cases run via automation.')
      TestType.find_or_create_by_name(:name => 'jMeter', :description => 'For test cases to be run using jMeter.')
      TestType.find_or_create_by_name(:name => 'Sikuli', :description => 'For test cases to be run using Sikuli.')
      
      
      puts "Install is complete."
    end
  end

  desc "Create a basic demo environment"
  task :demo => :environment do
    # Start Creating the new items
    # =====================
    # Create products
    product1 = Product.create(:name => 'Sample Product A', :description => 'This is a sample product.')
    product2 = Product.create(:name => 'Sample Product B', :description => 'This is a sample product.')
    
    # Create Users
    User.all.each do |user|
      user.products << product1
      user.products << product2
      user.save
    end
    
    # Create categories for product 1
    prod1cat1 = Category.create(:name => 'Feature A', :product_id => product1.id)
    prod1subcat1 = Category.create(:name => 'Part 1', :category_id => prod1cat1.id)
    prod1subcat2 = Category.create(:name => 'Part 2', :category_id => prod1cat1.id)
    prod1subcat3 = Category.create(:name => 'Part 3', :category_id => prod1cat1.id)
    prod1cat2 = Category.create(:name => 'Feature B', :product_id => product1.id)
    prod1cat3 = Category.create(:name => 'Feature C', :product_id => product1.id)

    prod2cat1 = Category.create(:name => 'Compatibility', :product_id => product2.id)
    prod2cat2 = Category.create(:name => 'Performance', :product_id => product2.id)
    prod2cat3 = Category.create(:name => 'Stability', :product_id => product2.id)
    prod2cat4 = Category.create(:name => 'New Features', :product_id => product2.id)
    
    # Create versions for product 1
    prod1v1 = Version.create(:version => "v1.0", :description => "First release", :product_id => product1.id)
    prod1v2 = Version.create(:version => "v2.0", :description => "Second release", :product_id => product1.id)
    prod1v3 = Version.create(:version => "v3.0", :description => "Third release", :product_id => product1.id)
    
    prod2v1 = Version.create(:version => "v1.0.0", :description => "Release 1.0.0", :product_id => product2.id)
    prod2v2 = Version.create(:version => "v1.0.1", :description => "Release 1.0.1", :product_id => product2.id)
    prod2v3 = Version.create(:version => "v1.1.0", :description => "Release 1.1.0", :product_id => product2.id)

    # Find the manual test type for use in cases
    testtype1 = TestType.where(:name => 'Manual').first

    # Test cases for product 1   (all sub categories)
    testcase2001 = TestCase.create(:name => 'Test case 1', :description => 'Verify index page layout is correct', :test_type_id => testtype1.id, :category_id => prod1cat1.id, :product_id => product1.id )
    testcase2002 = TestCase.create(:name => 'Test case 2', :description => 'Verify contact us page layout is correct', :test_type_id => testtype1.id, :category_id => prod1cat1.id, :product_id => product1.id )
    testcase2003 = TestCase.create(:name => 'Test case 3', :description => 'Verify directions page layout is correct', :test_type_id => testtype1.id, :category_id => prod1cat1.id, :product_id => product1.id )
    testcase2004 = TestCase.create(:name => 'Test case 4', :description => 'Verify about us page layout is correct', :test_type_id => testtype1.id, :category_id => prod1cat2.id, :product_id => product1.id )
    testcase2005 = TestCase.create(:name => 'Test case 5', :description => 'Verify index page layout is correct', :test_type_id => testtype1.id, :category_id => prod1cat2.id, :product_id => product1.id )
    testcase2006 = TestCase.create(:name => 'Test case 6', :description => 'Verify that item 6 is correct', :test_type_id => testtype1.id, :category_id => prod1subcat1.id, :product_id => product1.id )
    testcase2007 = TestCase.create(:name => 'Test case 7', :description => 'Verify that item 7 is correct', :test_type_id => testtype1.id, :category_id => prod1subcat1.id, :product_id => product1.id )
    testcase2008 = TestCase.create(:name => 'Test case 8', :description => 'Verify that item 8 is correct', :test_type_id => testtype1.id, :category_id => prod1subcat1.id, :product_id => product1.id )
    testcase2009 = TestCase.create(:name => 'Test case 9', :description => 'Verify that item 9 is correct', :test_type_id => testtype1.id, :category_id => prod1subcat1.id, :product_id => product1.id )    
    testcase2010 = TestCase.create(:name => 'Test case 10', :description => 'Verify that item 10 is correct', :test_type_id => testtype1.id, :category_id => prod1subcat2.id, :product_id => product1.id )

    # Create steps fo Product 1 test cases 
    testcase2001.steps.build(:action => "Log in to the application", :result => "Log in successful", :step_number => 1)
    testcase2001.steps.build(:action => "Click item A ", :result => "See a result", :step_number => 2)
    testcase2001.steps.build(:action => "Click item B", :step_number => 3)
    testcase2001.steps.build(:action => "Click item C", :result => "Page loads and displays a success message", :step_number => 4)
    testcase2001.save
    testcase2002.steps.build(:action => "Log in to the application", :result => "Log in successful", :step_number => 1)
    testcase2002.steps.build(:action => "Click item D ", :result => "See a result", :step_number => 2)
    testcase2002.steps.build(:action => "Click item E", :step_number => 3)
    testcase2002.steps.build(:action => "Click item F", :result => "Page loads and displays a success message", :step_number => 4)
    testcase2002.save
    testcase2003.steps.build(:action => "Log in to the application", :result => "Log in successful", :step_number => 1)
    testcase2003.steps.build(:action => "Click item G ", :result => "See a result", :step_number => 2)
    testcase2003.steps.build(:action => "Click item H", :step_number => 3)
    testcase2003.steps.build(:action => "Click item I", :result => "Page loads and displays a success message", :step_number => 4) 
    testcase2003.save
    testcase2004.steps.build(:action => "Log in to the application", :result => "Log in successful", :step_number => 1)
    testcase2004.steps.build(:action => "Click item J ", :result => "See a result", :step_number => 2)
    testcase2004.steps.build(:action => "Click item K", :step_number => 3)
    testcase2004.steps.build(:action => "Click item L", :result => "Page loads and displays a success message", :step_number => 4)
    testcase2004.save
    testcase2005.steps.build(:action => "Log in to the application", :result => "Log in successful", :step_number => 1)
    testcase2005.steps.build(:action => "Click item M ", :result => "See a result", :step_number => 2)
    testcase2005.steps.build(:action => "Click item N", :step_number => 3)
    testcase2005.steps.build(:action => "Click item O", :result => "Page loads and displays a success message", :step_number => 4)
    testcase2006.save
    testcase2006.steps.build(:action => "Log in to the application", :result => "Log in successful", :step_number => 1)
    testcase2006.steps.build(:action => "Click item P ", :result => "See a result", :step_number => 2)
    testcase2006.steps.build(:action => "Click item Q", :step_number => 3)
    testcase2006.steps.build(:action => "Click item R", :result => "Page loads and displays a success message", :step_number => 4)
    testcase2006.save
    testcase2007.steps.build(:action => "Log in to the application", :result => "Log in successful", :step_number => 1)
    testcase2007.steps.build(:action => "Click item S ", :result => "See a result", :step_number => 2)
    testcase2007.steps.build(:action => "Click item T", :step_number => 3)
    testcase2007.steps.build(:action => "Click item U", :result => "Page loads and displays a success message", :step_number => 4)
    testcase2007.save
    testcase2008.steps.build(:action => "Log in to the application", :result => "Log in successful", :step_number => 1)
    testcase2008.steps.build(:action => "Click item V ", :result => "See a result", :step_number => 2)
    testcase2008.steps.build(:action => "Click item W", :step_number => 3)
    testcase2008.steps.build(:action => "Click item X", :result => "Page loads and displays a success message", :step_number => 4)
    testcase2008.save
    testcase2009.steps.build(:action => "Log in to the application", :result => "Log in successful", :step_number => 1)
    testcase2009.steps.build(:action => "Click item Y ", :result => "See a result", :step_number => 2)
    testcase2009.steps.build(:action => "Click item Z", :step_number => 3)
    testcase2009.steps.build(:action => "Click item A", :result => "Page loads and displays a success message", :step_number => 4)
    testcase2009.save
    testcase2010.steps.build(:action => "Log in to the application", :result => "Log in successful", :step_number => 1)
    testcase2010.steps.build(:action => "Click item B ", :result => "See a result", :step_number => 2)
    testcase2010.steps.build(:action => "Click item C", :step_number => 3)
    testcase2010.steps.build(:action => "Click item D", :result => "Page loads and displays a success message", :step_number => 4)
    testcase2010.save

    
    # Create the first test plan
    testplan1 = TestPlan.create(:name => 'Regression Test Plan', :description => 'This is a sample test plan for Sample Product 1.', :product_id => product1.id)
    # Add the cases to the test plan
    testplan1.test_cases << testcase2001
    testplan1.test_cases << testcase2002
    testplan1.test_cases << testcase2003
    testplan1.test_cases << testcase2004
    testplan1.test_cases << testcase2005

    # Set the case order for the test cases
    i=1
    testplan1.plan_cases.each do |plan_case|
     plan_case.case_order = i
     plan_case.save
     i += 1
    end
    
    # PRODUCT 2
    # Test cases for product 1   (all sub categories)
    testcase2101 = TestCase.create(:name => 'Test case A', :description => 'Verify index page layout is correct', :test_type_id => testtype1.id, :category_id => prod2cat1.id, :product_id => product2.id )
    testcase2102 = TestCase.create(:name => 'Test case B', :description => 'Verify contact us page layout is correct', :test_type_id => testtype1.id, :category_id => prod2cat1.id, :product_id => product2.id )
    testcase2103 = TestCase.create(:name => 'Test case C', :description => 'Verify directions page layout is correct', :test_type_id => testtype1.id, :category_id => prod2cat1.id, :product_id => product2.id )
    testcase2104 = TestCase.create(:name => 'Test case D', :description => 'Verify about us page layout is correct', :test_type_id => testtype1.id, :category_id => prod2cat2.id, :product_id => product2.id )
    testcase2105 = TestCase.create(:name => 'Test case E', :description => 'Verify index page layout is correct', :test_type_id => testtype1.id, :category_id => prod2cat2.id, :product_id => product2.id )

    # Create steps fo Product 1 test cases 
    testcase2101.steps.build(:action => "Log in to the application", :result => "Log in successful", :step_number => 1)
    testcase2101.steps.build(:action => "Click item A ", :result => "See a result", :step_number => 2)
    testcase2101.steps.build(:action => "Click item B", :step_number => 3)
    testcase2101.steps.build(:action => "Click item C", :result => "Page loads and displays a success message", :step_number => 4)
    testcase2101.save
    testcase2102.steps.build(:action => "Log in to the application", :result => "Log in successful", :step_number => 1)
    testcase2102.steps.build(:action => "Click item A ", :result => "See a result", :step_number => 2)
    testcase2102.steps.build(:action => "Click item B", :step_number => 3)
    testcase2102.steps.build(:action => "Click item C", :result => "Page loads and displays a success message", :step_number => 4)
    testcase2102.save
    testcase2103.steps.build(:action => "Log in to the application", :result => "Log in successful", :step_number => 1)
    testcase2103.steps.build(:action => "Click item A ", :result => "See a result", :step_number => 2)
    testcase2103.steps.build(:action => "Click item B", :step_number => 3)
    testcase2103.steps.build(:action => "Click item C", :result => "Page loads and displays a success message", :step_number => 4) 
    testcase2103.save
    testcase2104.steps.build(:action => "Log in to the application", :result => "Log in successful", :step_number => 1)
    testcase2104.steps.build(:action => "Click item A ", :result => "See a result", :step_number => 2)
    testcase2104.steps.build(:action => "Click item B", :step_number => 3)
    testcase2104.steps.build(:action => "Click item C", :result => "Page loads and displays a success message", :step_number => 4)
    testcase2104.save
    testcase2105.steps.build(:action => "Log in to the application", :result => "Log in successful", :step_number => 1)
    testcase2105.steps.build(:action => "Click item A ", :result => "See a result", :step_number => 2)
    testcase2105.steps.build(:action => "Click item B", :step_number => 3)
    testcase2105.steps.build(:action => "Click item C", :result => "Page loads and displays a success message", :step_number => 4)
    testcase2105.save
    
    # Create the first test plan
    testplan2 = TestPlan.create(:name => 'System Test Test Plan', :description => 'This is a sample test plan for Sample Product 1.', :product_id => product2.id)
    # Add the cases to the test plan
    testplan2.test_cases << testcase2101
    testplan2.test_cases << testcase2102
    testplan2.test_cases << testcase2103
    testplan2.test_cases << testcase2104
    testplan2.test_cases << testcase2105
    # Set the case order for the test cases
    i=1
    testplan2.plan_cases.each do |plan_case|
     plan_case.case_order = i
     plan_case.save
     i += 1
    end
    
    
    # Create assignments
    assignment1 = Assignment.create(:notes => 'Execute the regression test plan for release 1.0.', :version_id => prod1v1.id, :test_plan_id => testplan1.id, :product_id => product1.id )
    assignment1.task = Task.create(:user_id => User.first.id, :task => 4, :status => 0, :due_date => Date.today - 7.days, :name => "Execute " + assignment1.test_plan.name + " against " + assignment1.version.version)
    assignment1.test_plan.test_cases.each do |testCase|
      assignment1.results.create(:test_case_id => testCase.id)
    end
    
    assignment2 = Assignment.create(:notes => 'Execute the regression test plan for release 2.0.', :version_id => prod1v2.id, :test_plan_id => testplan1.id, :product_id => product1.id )
    assignment2.task = Task.create(:user_id => User.first.id, :task => 4, :status => 0, :due_date => Date.today + 1.days, :name => "Execute " + assignment2.test_plan.name + " against " + assignment2.version.version)
    assignment2.test_plan.test_cases.each do |testCase|
      assignment2.results.create(:test_case_id => testCase.id)
    end
    
    assignment3 = Assignment.create(:notes => 'Execute the regression test plan for release 3.0.', :version_id => prod1v3.id, :test_plan_id => testplan1.id, :product_id => product1.id )
    assignment3.task = Task.create(:user_id => User.first.id, :task => 4, :status => 0, :due_date => Date.today + 7.days, :name => "Execute " + assignment3.test_plan.name + " against " + assignment3.version.version)
    assignment3.test_plan.test_cases.each do |testCase|
      assignment3.results.create(:test_case_id => testCase.id)
    end
    
    # Mark results for first assignment
    # Set status for all results and close task
    i = 0
    assignment1.results.each do |result|
      if i % 2 == 0
        result.result = 'Passed'
      else
        result.result = 'Failed'
      end
      i = i+ 1
      result.save
    end
    assignment1.task.status = 127
    assignment1.task.save
    
    # Mark results for second assignment
    # only update first two results (so it is in progress)
    i = 1
    assignment2.results.each do |result|
      if i == 1
        result.result = 'Passed'
        result.save
      elsif i == 2 
        result.result = 'Passed'
        result.save
      end
      i = i+ 1
    end
    
    # Create Reports
    report1 = Report.create(:product_id => product1.id, :version_id => prod1v2.id, :report_type => "Release Current State")
    report1.user = User.first
    report1.save
    report2 = Report.create(:product_id => product1.id, :version_id => prod1v2.id, :report_type => "Compare Release Results")
    report2.user = User.first
    report2.save
    
    # Create Custom fields
    os_field = CustomField.create(:field_name => 'Operating System', :item_type => 'device', :field_type => 'drop_down', :active => true, :accepted_values => 'Windows XP,Windows Vista,Windows 7,Windows 8,Ubuntu 12.04,Ubuntu 12.10')
    os_field.save
    ram_field = CustomField.create(:field_name => 'RAM (MB)', :item_type => 'device', :field_type => 'number', :active => true, :accepted_values => '')
    ram_field.save
    
    # Create Devices
    device1 = Device.create(:name => 'Windows 7 - Regular', :description => 'Windows 7 desktop with standard RAM', :active => false)
    device1.save
    item = CustomItem.create(:device_id => device1.id, :custom_field_id => os_field.id, :value => 'Windows 7')
    item.save
    item = CustomItem.create(:device_id => device1.id, :custom_field_id => ram_field.id, :value => '4096')
    item.save
    device2 = Device.create(:name => 'Windows 8 - Regular', :description => 'Windows 8 desktop with standard RAM', :active => false)
    device2.save
    item = CustomItem.create(:device_id => device2.id, :custom_field_id => os_field.id, :value => 'Windows 8')
    item.save
    item = CustomItem.create(:device_id => device2.id, :custom_field_id => ram_field.id, :value => '4096')
    item.save
    
    # Create a stencil
    stencil1 = Stencil.create(:product_id => product1.id, :name => 'Sample Regression Stencil', :description => "This simple stencil shows how they can be used.\n\nStencils can use multiple test plans or a single one as this example demonstrates.")
    stencil1.stencil_test_plans .build(:test_plan_id => testplan1.id, :device_id => device1.id, :plan_order => 1)
    stencil1.stencil_test_plans .build(:test_plan_id => testplan1.id, :device_id => device2.id, :plan_order => 1)
    stencil1.save
  end

  desc "Larger demo with more data"
  task :largedemo => :environment do  
    testtype1 = TestType.where(:name => 'Manual').first
    
    # Start Creating the new items
    # =====================
    # Create products
    products = []
    ('A'..'J').each do |p_letter|
      products << Product.create(:name => 'Sample Product ' + p_letter, :description => 'This is a sample product.')
    end
        
    products.each do |product|
      # Create categories for product 1
      categories = []
      ('A'..'E').each do |c_letter|
        categories << Category.create(:name => 'Feature ' + c_letter, :product_id => product.id)
      end
      
      # Create the test case. For each category creat 10 test cases
      testcases = []
      categories.each do |category|
        (1..20).each do |i|
          testcases << TestCase.create(:name => "Test case #{i} for #{category.name}", :description => "This is test case number #{i}", :test_type_id => testtype1.id, :category_id => category.id, :product_id => product.id )
        end
      end
      
      # Add steps to each test case
      testcases.each do |tc|
        (1..10).each do |step_num|
          tc.steps.build(:action => "This is step number #{step_num.to_s}.", :result => "This is result  #{step_num.to_s}.", :step_number => step_num)
        end
        tc.save
      end
      
      testplans = []
      (1..10).each do |plan_num|
        tp = TestPlan.create(:name => "#{product.name}: Test Plan #{plan_num.to_s}", :description => "This is a sample test plan for #{product.name}.", :product_id => product.id)
        tp.test_cases << testcases
        tp.save
        
        i=1
        tp.plan_cases.each do |plan_case|
          plan_case.case_order = i
          plan_case.save
          i += 1
        end
      end
    end
  end

end
