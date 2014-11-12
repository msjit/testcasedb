require "webapi/webapi_spec_helper"

RSpec.describe 'Assignments API', :type => :request do

  before(:each) do
    @product = Product.create(FactoryGirl.attributes_for(:product))
    @category = Category.create(FactoryGirl.attributes_for(:category))
    @sub_category = Category.create(FactoryGirl.attributes_for(:sub_category))
    @version = Version.create(FactoryGirl.attributes_for(:version))      
    @test_case = TestCase.create(FactoryGirl.attributes_for(:test_case))
    @test_case_2 = TestCase.create(FactoryGirl.attributes_for(:test_case_2))       
    @test_plan = TestPlan.create(FactoryGirl.attributes_for(:test_plan))
    @test_plan_2 = TestPlan.create(FactoryGirl.attributes_for(:test_plan_2))
    @plan_case = PlanCase.create(FactoryGirl.attributes_for(:plan_case))
    @plan_case_2 = PlanCase.create(FactoryGirl.attributes_for(:plan_case_2))
    @plan_case_3 = PlanCase.create(FactoryGirl.attributes_for(:plan_case_3))     
    @device = Device.create(FactoryGirl.attributes_for(:device))
    @device_2 = Device.create(FactoryGirl.attributes_for(:device_2))
    @stencil_attr_hash = FactoryGirl.attributes_for(:stencil)
    @stencil_test_plan = StencilTestPlan.create(FactoryGirl.attributes_for(:stencil_test_plan))
    @stencil_test_plan_2 = StencilTestPlan.create(FactoryGirl.attributes_for(:stencil_test_plan_2))
    @test_plan_assignment_attr_hash = FactoryGirl.attributes_for(:test_plan_assignment)
    @stencil_assignment_attr_hash = FactoryGirl.attributes_for(:stencil_assignment)
  end
      
  it "search not found" do
    params = {
      "api_key" => @user.single_access_token,
      'id' => 1,
      'product_id' => 1,
      'test_plan_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/assignments/search.json", params, request_headers    
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['found']).to eq(false)
    @test_plan_assignment = Assignment.create(@test_plan_assignment_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'id' => 2
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/assignments/search.json", params, request_headers    
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['found']).to eq(false)    
  end
  
  it "search test plan assignment found" do
    @test_plan_assignment = Assignment.create(@test_plan_assignment_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'id' => 1,
      'product_id' => 1,
      'product_version_id' => 1,
      'test_plan_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/assignments/search.json", params, request_headers    
    expect(response.status).to eq(200) 
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['assignments'].count).to eq(1)
    params = {
      "api_key" => @user.single_access_token,
      'id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/assignments/search.json", params, request_headers    
    expect(response.status).to eq(200) 
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['assignments'].count).to eq(1)
    params = {
      "api_key" => @user.single_access_token,
      'test_plan_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/assignments/search.json", params, request_headers    
    expect(response.status).to eq(200) 
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['assignments'].count).to eq(1)
    expect(response.status).to eq(200) 
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['assignments'].count).to eq(1)
    params = {
      "api_key" => @user.single_access_token,
      'product_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/assignments/search.json", params, request_headers    
    expect(response.status).to eq(200) 
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['assignments'].count).to eq(1)
    @stencil_assignment = Assignment.create(@stencil_assignment_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'stencil_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/assignments/search.json", params, request_headers    
    expect(response.status).to eq(200) 
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['assignments'].count).to eq(1)                 
  end  
    
  it "verify test plan assignment return order" do
    @test_plan_assignment = Assignment.create(@test_plan_assignment_attr_hash)
    @stencil_assignment = Assignment.create(@stencil_assignment_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'product_id' => 1,
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/assignments/search.json", params, request_headers    
    expect(response.status).to eq(200) 
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['assignments'].count).to eq(2)
    expect(JSON.parse(response.body)['assignments'][0]['id']).to eq(@test_plan_assignment.id)
    expect(JSON.parse(response.body)['assignments'][1]['id']).to eq(@stencil_assignment.id)
  end
  
  it "create fails with invalid version" do
    params = {
      "api_key" => @user.single_access_token,
      'product_id' => 1,
      'product_version_id' => 3,
      'test_plan_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/assignments/create.json", params, request_headers    
    expect(response.status).to eq(400)
    params = {
      "api_key" => @user.single_access_token,
      'id' => 1,
      'product_id' => 1,
      'product_version' => 'asdf',
      'test_plan_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/assignments/create.json", params, request_headers    
    expect(response.status).to eq(400)       
  end     

  it "create fails with invalid product" do
    params = {
      "api_key" => @user.single_access_token,
      'product_id' => 3,
      'product_version_id' => 1,
      'test_plan_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/assignments/create.json", params, request_headers    
    expect(response.status).to eq(400)
    params = {
      "api_key" => @user.single_access_token,
      'product_name' => 'qwer',
      'product_version_id' => 1,
      'test_plan_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/assignments/create.json", params, request_headers    
    expect(response.status).to eq(400)        
  end 
      
  it "create fails without stencil_id or test_plan_id" do
    params = {
      "api_key" => @user.single_access_token,
      'product_id' => 1,
      'product_version_id' => 1,
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/assignments/create.json", params, request_headers    
    expect(response.status).to eq(400)      
  end       
      
  it "create fails with invalid stencil_id" do
    params = {
      "api_key" => @user.single_access_token,
      'product_id' => 1,
      'product_version_id' => 1,
      'stencil_id' => 3
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/assignments/create.json", params, request_headers    
    expect(response.status).to eq(400)      
  end       
  
  it "create fails with invalid test_plan_id" do
    params = {
      "api_key" => @user.single_access_token,
      'product_id' => 1,
      'product_version_id' => 1,
      'test_plan_id' => 3
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/assignments/create.json", params, request_headers   
    expect(response.status).to eq(400)      
  end   
      
  it "create with test plan successful" do
    params = {
      "api_key" => @user.single_access_token,
      'product_id' => 1,
      'product_version_id' => 1,
      'test_plan_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/assignments/create.json", params, request_headers   
    expect(response.status).to eq(201)
    expect(JSON.parse(response.body)['id']).to eq(1)
    expect(JSON.parse(response.body)['product_id']).to eq(1)
    expect(JSON.parse(response.body)['product_version_id']).to eq(1)
    expect(JSON.parse(response.body)['test_plan_id']).to eq(1)
    expect(JSON.parse(response.body)['results'].count).to eq(2)     
  end       
     
  it "create with stencil successful" do
    @stencil = Stencil.create(@stencil_attr_hash)   
    params = {
      "api_key" => @user.single_access_token,
      'product_id' => 1,
      'product_version_id' => 1,
      'stencil_id' => @stencil.id
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/assignments/create.json", params, request_headers    
    expect(JSON.parse(response.body)['id']).to eq(1)
    expect(JSON.parse(response.body)['product_id']).to eq(1)
    expect(JSON.parse(response.body)['product_version_id']).to eq(1)    
    expect(JSON.parse(response.body)['stencil_id']).to eq(@stencil.id)
    expect(JSON.parse(response.body)['results'].count).to eq(3)
    expect(JSON.parse(response.body)['results'][0]['test_case_id']).to eq(@test_case.id)
    expect(JSON.parse(response.body)['results'][0]['device_id']).to eq(@device.id)
    expect(JSON.parse(response.body)['results'][1]['test_case_id']).to eq(@test_case_2.id)
    expect(JSON.parse(response.body)['results'][1]['device_id']).to eq(@device.id)
    expect(JSON.parse(response.body)['results'][2]['test_case_id']).to eq(@test_case.id)
    expect(JSON.parse(response.body)['results'][2]['device_id']).to eq(@device_2.id)          
  end
          
end