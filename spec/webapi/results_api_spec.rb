require "webapi/webapi_spec_helper"

RSpec.describe 'Results API', :type => :request do
  
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
    @stencil_test_plan = StencilTestPlan.create(FactoryGirl.attributes_for(:stencil_test_plan_2))
    @test_plan_assignment = Assignment.create(FactoryGirl.attributes_for(:test_plan_assignment))
    @stencil_assignment = Assignment.create(FactoryGirl.attributes_for(:stencil_assignment))
    @result = Result.create(FactoryGirl.attributes_for(:result))
    @result_2 = Result.create(FactoryGirl.attributes_for(:result_2))
    @result_3 = Result.create(FactoryGirl.attributes_for(:result_3))
  end  
   
  it "get not found" do
    params = {
      "api_key" => @user.single_access_token,
      'id' => 11
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/results/get.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['found']).to eq(false) 
  end

  it "get by id found" do
    params = {
      "api_key" => @user.single_access_token,
      'id' => @result.id
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/results/get.json", params, request_headers
    expect(response.status).to eq(200)       
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['results'].count).to eq(1)
    expect(JSON.parse(response.body)['results'][0]['id']).to eq(@result.id)
  end 
  
  it "get multiple by test_case_id found" do
    params = {
      "api_key" => @user.single_access_token,
      'test_case_id' => 11
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/results/get.json", params, request_headers
    expect(response.status).to eq(200)    
    expect(JSON.parse(response.body)['results'].count).to eq(2)
    expect(JSON.parse(response.body)['results'][0]['test_case_id']).to eq(11)
    expect(JSON.parse(response.body)['results'][1]['test_case_id']).to eq(11)
  end
  
  it "get multiple by assignment_id found" do
    params = {
      "api_key" => @user.single_access_token,
      'assignment_id' => 12
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/results/get.json", params, request_headers
    expect(response.status).to eq(200)    
    expect(JSON.parse(response.body)['results'].count).to eq(2)
    expect(JSON.parse(response.body)['results'][0]['assignment_id']).to eq(12)
    expect(JSON.parse(response.body)['results'][0]['test_case_id']).to eq(11)
    expect(JSON.parse(response.body)['results'][1]['assignment_id']).to eq(12)
    expect(JSON.parse(response.body)['results'][1]['test_case_id']).to eq(12)
  end  
  
  it "get multiple by device_id found" do
    params = {
      "api_key" => @user.single_access_token,
      'device_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/results/get.json", params, request_headers
    expect(response.status).to eq(200)    
    expect(JSON.parse(response.body)['results'].count).to eq(3)
  end

  it "set no results passed failure" do
    params = {
      "api_key" => @user.single_access_token
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/results/set.json", params, request_headers
    expect(response.status).to eq(400)
  end 
  
  it "set invalid results passed failure" do
    params = {
      "api_key" => @user.single_access_token,
      "results" => 'not a hash'
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/results/set.json", params, request_headers
    expect(response.status).to eq(400)
    params = {
      "api_key" => @user.single_access_token,
      "results" => {}
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/results/set.json", params, request_headers
    expect(response.status).to eq(400)
    params = {
      "api_key" => @user.single_access_token,
      "results" => {0 => 1}
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/results/set.json", params, request_headers
    expect(response.status).to eq(400) 
    params = {
      "api_key" => @user.single_access_token,
      "results" => {0 => {'result' => 'adsf'}}
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/results/set.json", params, request_headers
    expect(response.status).to eq(400)               
  end

  it "set result alread set failure" do
    params = {
      "api_key" => @user.single_access_token,
      "results" => {@result.id => {'result' => 'Passed'}}
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/results/set.json", params, request_headers
    expect(response.status).to eq(400)
  end  
  
  it "set results success" do
    params = {
      "api_key" => @user.single_access_token,
      "results" => {@result_2.id => {'result' => 'Failed'},
                    @result_3.id => {'result' => 'Blocked'}}
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/results/set.json", params, request_headers    
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['results'].count).to eq(2)
  end 
  
  it "set results with custom fieldssuccess" do
    custom_fields_1 = {
      'field 1'=> {'name' => 'custom field 1-1',
                   'value' => '1',
                   'type' => 'string'},
      'field 2'=> {'name' => 'custom field 2-1',
                   'value' => '2',
                   'type' => 'string'}                   
    }    
    custom_fields_2 = {
      'field 1'=> {'name' => 'custom field 2-1',
                   'value' => '1',
                   'type' => 'string'},
      'field 2'=> {'name' => 'custom field 2-2',
                   'value' => '2',
                   'type' => 'string'}                   
    }       
    params = {
      "api_key" => @user.single_access_token,
      "results" => {@result_2.id => {'result' => 'Failed', 'custom_fields' => custom_fields_1},
                    @result_3.id => {'result' => 'Blocked', 'custom_fields' => custom_fields_2}}
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/results/set.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['results'].count).to eq(2)
    # get and verify
    params = {
      "api_key" => @user.single_access_token,
      'assignment_id' => @result_2.assignment_id
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/results/get.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['results'].count).to eq(2)
    expect(JSON.parse(response.body)['results'][0]['id']).to eq(@result_2.id)
    expect(JSON.parse(response.body)['results'][0]['custom_fields'].count).to eq(2)
    expect(JSON.parse(response.body)['results'][0]['custom_fields'][0]).to eq(custom_fields_1['field 1'])
    expect(JSON.parse(response.body)['results'][0]['custom_fields'][1]).to eq(custom_fields_1['field 2'])
    expect(JSON.parse(response.body)['results'][1]['id']).to eq(@result_3.id)
    expect(JSON.parse(response.body)['results'][1]['custom_fields'].count).to eq(2)
    expect(JSON.parse(response.body)['results'][1]['custom_fields'][0]).to eq(custom_fields_2['field 1'])
    expect(JSON.parse(response.body)['results'][1]['custom_fields'][1]).to eq(custom_fields_2['field 2'])        
  end       
      
end