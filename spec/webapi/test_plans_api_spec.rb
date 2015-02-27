require "webapi/webapi_spec_helper"

RSpec.describe 'Test Plans API', :type => :request do
  
  before(:each) do
    @product = Product.create(FactoryGirl.attributes_for(:product))
    @category = Category.create(FactoryGirl.attributes_for(:category))
    @sub_category = Category.create(FactoryGirl.attributes_for(:sub_category))
    @version = Version.create(FactoryGirl.attributes_for(:version))      
    @test_case = TestCase.create(FactoryGirl.attributes_for(:test_case))
    @test_case_2 = TestCase.create(FactoryGirl.attributes_for(:test_case_2))       
    @test_plan_attr_hash = FactoryGirl.attributes_for(:test_plan)
    @test_plan_attr_hash_2 = FactoryGirl.attributes_for(:test_plan_2)  
    @plan_case_attr_hash = FactoryGirl.attributes_for(:plan_case) 
    @plan_case_attr_hash_2 = FactoryGirl.attributes_for(:plan_case_2)
    @custom_fields = [{'name' => 'custom field 1',
                       'value' => '1',
                       'type' => 'string'},
                      {'name' => 'custom field 2',
                       'value' => '2',
                       'type' => 'string'}]              
  end  
   
  it "statuses return" do
    params = {
      "api_key" => @user.single_access_token
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_plans/statuses.json", params, request_headers
    expect(JSON.parse(response.body)['statuses']).to eq((I18n.t :item_status).stringify_keys)      
    expect(response.status).to eq(200) 
  end       
   
  it "search not found" do
    params = {
      "api_key" => @user.single_access_token,
      'product_id' => 1,
      'id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_plans/search.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['found']).to eq(false)     
  end
  
  it "no search parameters" do
    params = {
      "api_key" => @user.single_access_token,
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_plans/search.json", params, request_headers
    expect(response.status).to eq(400)     
  end  
  
  it "search found" do
    @test_plan = TestPlan.create(@test_plan_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'product_id' => 1,
      'id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_plans/search.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['test_plans'].count).to eq(1)
    expect(JSON.parse(response.body)['test_plans'][0]['test_cases'].count).to eq(0)
    params = {
      "api_key" => @user.single_access_token,
      'product_id' => 1,
      'name' => @test_plan.name
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_plans/search.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['found']).to eq(true)    
  end  
 
   it "search multiple found" do
    @test_plan = TestPlan.create(@test_plan_attr_hash)
    @test_plan_2 = TestPlan.create(@test_plan_attr_hash_2)
    params = {
      "api_key" => @user.single_access_token,
      'product_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_plans/search.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['test_plans'].count).to eq(2) 
  end 
  
   it "search using deprecated found" do
    @test_plan = TestPlan.create(@test_plan_attr_hash)
    @test_plan_2 = TestPlan.create(@test_plan_attr_hash_2)
    @test_plan_2.deprecated = true
    @test_plan_2.save
    @test_plan_2.reload
    params = {
      "api_key" => @user.single_access_token,
      'product_id' => 1,
      'deprecated' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_plans/search.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['test_plans'].count).to eq(1) 
    expect(JSON.parse(response.body)['test_plans'][0]['id']).to eq(@test_plan_2.id)
    params = {
      "api_key" => @user.single_access_token,
      'product_id' => 1,
      'deprecated' => 0
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_plans/search.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['test_plans'].count).to eq(1) 
    expect(JSON.parse(response.body)['test_plans'][0]['id']).to eq(@test_plan.id)      
  end  
 
  it "create fails with wrong product" do
    name = 'Test Plan'
    params = {
      "api_key" => @user.single_access_token,
      'name' => name,
      'product_id' => 'nonexistent product',      
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_plans/create.json", params, request_headers  
    expect(response.status).to eq(400) 
  end 
  
  it "create fails with bad user id" do
    name = 'Test Plan'
    params = {
      "api_key" => @user.single_access_token,
      'name' => name,      
      'product_id' => 1,
      'created_by_id' => 2
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_plans/create.json", params, request_headers
    expect(response.status).to eq(400) 
  end  
  
  it "create successful" do
    name = 'Test Plan'
    description = 'test plan'
    params = {
      "api_key" => @user.single_access_token,
      'name' => name,
      'product_id' => 1,      
      'description' => description,
      'custom_fields' => @custom_fields
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_plans/create.json", params, request_headers  
    expect(response.status).to eq(201)
    expect(JSON.parse(response.body)['id']).to eq(1)  
    expect(JSON.parse(response.body)['parent_id']).to eq(nil) 
    expect(JSON.parse(response.body)['custom_fields'].count).to eq(2)
    expect(JSON.parse(response.body)['test_cases'].count).to eq(0)
  end    
  
  it "create new version successful" do
    name = 'Test PLan'
    description = 'test plan'
    params = {
      "api_key" => @user.single_access_token,
      'name' => name,
      'product_id' => 1,      
      'description' => description,
      'custom_fields' => @custom_fields 
    }
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_plans/create.json", params.to_json, request_headers  
    expect(response.status).to eq(201) 
    expect(JSON.parse(response.body)['id']).to eq(1)  
    expect(JSON.parse(response.body)['parent_id']).to eq(nil)
    expect(JSON.parse(response.body)['test_cases'].count).to eq(0)      
    # new version
    params['new_version'] = true
    post "api/test_plans/create.json", params.to_json, request_headers
    expect(response.status).to eq(201)
    expect(JSON.parse(response.body)['version']).to eq(2) 
    expect(JSON.parse(response.body)['custom_fields'].count).to eq(2)
    expect(JSON.parse(response.body)['test_cases'].count).to eq(0)
  end 

  it "update successful" do
    @test_plan = TestPlan.create(@test_plan_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'product_id' => 1,
      'id' => 1
    }
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_plans/search.json", params.to_json, request_headers    
    expect(response.status).to eq(200) 
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['test_plans'].count).to eq(1)
    @test_plans = JSON.parse(response.body)['test_plans'][0]
    expect(@test_plans['name']).to eq(@test_plan.name)
    expect(@test_plans['description']).to eq(@test_plan.description)
    expect(@test_plans['version']).to eq(@test_plan.version)
    expect(@test_plans['parent_id']).to eq(@test_plan.parent_id)
    expect(@test_plans['product_id']).to eq(@test_plan.product.id)
    expect(@test_plans['custom_fields']).to eq([])
    expect(@test_plans['status']).to eq((I18n.t :item_status)[@test_plan.status])
    expect(@test_plans['test_cases'].count).to eq(0)       
    # update
    name = 'Updated name'
    description = 'updated description'
    params['overwrite_custom_fields'] = true  
    params = {
      'api_key' => @user.single_access_token,
      'to_update' => {
        'id' => @test_plan.id,
        'product_id' => 1,            
      },
      'new_values' => {  
        'name' => name,
        'product_id' => 1, 
        'description' => description,
        'custom_fields' => @custom_fields,
        'overwrite_custom_fields' => true      
      },      
    }      
    post "api/test_plans/update.json", params.to_json, request_headers   
    @test_plan.reload 
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['name']).to eq(name)
    expect(JSON.parse(response.body)['description']).to eq(description)
    expect(JSON.parse(response.body)['version']).to eq(@test_plan.version)
    expect(JSON.parse(response.body)['parent_id']).to eq(@test_plan.parent_id)
    expect(JSON.parse(response.body)['product_id']).to eq(@test_plan.product.id)   
    expect(JSON.parse(response.body)['custom_fields'].count).to eq(2)
    expect(JSON.parse(response.body)['custom_fields'][0]).to eq(@custom_fields[0])
    expect(JSON.parse(response.body)['custom_fields'][1]).to eq(@custom_fields[1])
    expect(JSON.parse(response.body)['status']).to eq((I18n.t :item_status)[@test_plan.status])
    expect(JSON.parse(response.body)['test_cases'].count).to eq(0)    
  end 

  it "create with test cases successful" do   
    name = 'Test Plan'
    description = 'test plan'
    params = {
      "api_key" => @user.single_access_token,
      'name' => name,
      'product_id' => 1,      
      'description' => description,
      'test_cases' => [2,1]
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_plans/create.json", params, request_headers 
    expect(response.status).to eq(201)
    expect(JSON.parse(response.body)['test_cases'].count).to eq(2)
    expect(JSON.parse(response.body)['test_cases'][0]['test_case_id']).to eq(2)
    expect(JSON.parse(response.body)['test_cases'][0]['case_order']).to eq(0)
    expect(JSON.parse(response.body)['test_cases'][1]['test_case_id']).to eq(1)
    expect(JSON.parse(response.body)['test_cases'][1]['case_order']).to eq(1)
  end
 
  it "update with test cases successful" do
    @test_plan = TestPlan.create(@test_plan_attr_hash)       
    name = 'Test Plan'
    description = 'test plan'
    params = {
      "api_key" => @user.single_access_token,
      'name' => name,
      'product_id' => 1,      
      'description' => description      
    }
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_plans/search.json", params.to_json, request_headers    
    expect(response.status).to eq(200) 
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['test_plans'][0]['test_cases'].count).to eq(0)
    # update with test cases
    params = {
      'api_key' => @user.single_access_token,
      'to_update' => {
        'id' => @test_plan.id,
        'product_id' => 1,            
      },
      'new_values' => {  
        'test_cases' => [2,1]      
      }      
    }            
    post "api/test_plans/update.json", params.to_json, request_headers    
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['test_cases'].count).to eq(2)
    expect(JSON.parse(response.body)['version']).to eq(1)
    expect(JSON.parse(response.body)['test_cases'][0]['test_case_id']).to eq(2)
    expect(JSON.parse(response.body)['test_cases'][0]['case_order']).to eq(0)
    expect(JSON.parse(response.body)['test_cases'][1]['test_case_id']).to eq(1)
    expect(JSON.parse(response.body)['test_cases'][1]['case_order']).to eq(1) 
  end  

  it "update test case order successful" do
    @test_plan = TestPlan.create(@test_plan_attr_hash) 
    @plan_case = PlanCase.create(@plan_case_attr_hash) 
    @plan_case_2 = PlanCase.create(@plan_case_attr_hash_2)          
    name = 'Test Plan'
    description = 'test plan'
    params = {
      "api_key" => @user.single_access_token,
      'name' => name,
      'product_id' => 1,      
      'description' => description      
    }
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_plans/search.json", params.to_json, request_headers    
    expect(response.status).to eq(200) 
    expect(JSON.parse(response.body)['found']).to eq(true)
    @test_plans = JSON.parse(response.body)['test_plans']
    expect(@test_plans[0]['version']).to eq(1)
    expect(@test_plans[0]['test_cases'].count).to eq(2)
    expect(@test_plans[0]['test_cases'][0]['test_case_id']).to eq(1)
    expect(@test_plans[0]['test_cases'][0]['case_order']).to eq(0)
    expect(@test_plans[0]['test_cases'][1]['test_case_id']).to eq(2)
    expect(@test_plans[0]['test_cases'][1]['case_order']).to eq(1)    
    # update with test cases
    params = {
      'api_key' => @user.single_access_token,
      'to_update' => {
        'id' => @test_plan.id,
        'product_id' => 1,            
      },
      'new_values' => {  
        'test_cases' => [2,1]      
      }      
    }            
    post "api/test_plans/update.json", params.to_json, request_headers    
    expect(response.status).to eq(200)      
    expect(JSON.parse(response.body)['version']).to eq(2)
    expect(JSON.parse(response.body)['test_cases'].count).to eq(2)
    expect(JSON.parse(response.body)['test_cases'][0]['test_case_id']).to eq(2)
    expect(JSON.parse(response.body)['test_cases'][0]['case_order']).to eq(0)
    expect(JSON.parse(response.body)['test_cases'][1]['test_case_id']).to eq(1)
    expect(JSON.parse(response.body)['test_cases'][1]['case_order']).to eq(1)          
  end
 
  it "update test case removing one successful" do
    @test_plan = TestPlan.create(@test_plan_attr_hash) 
    @plan_case = PlanCase.create(@plan_case_attr_hash) 
    @plan_case_2 = PlanCase.create(@plan_case_attr_hash_2)          
    name = 'Test Plan'
    description = 'test plan'
    params = {
      "api_key" => @user.single_access_token,
      'name' => name,
      'product_id' => 1,      
      'description' => description      
    }
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_plans/search.json", params.to_json, request_headers    
    expect(response.status).to eq(200) 
    expect(JSON.parse(response.body)['found']).to eq(true)
    @test_plans = JSON.parse(response.body)['test_plans']
    expect(@test_plans[0]['version']).to eq(1)
    expect(@test_plans[0]['test_cases'].count).to eq(2)
    expect(@test_plans[0]['test_cases'][0]['test_case_id']).to eq(1)
    expect(@test_plans[0]['test_cases'][0]['case_order']).to eq(0)
    expect(@test_plans[0]['test_cases'][1]['test_case_id']).to eq(2)
    expect(@test_plans[0]['test_cases'][1]['case_order']).to eq(1)        
    # update with test cases
    params = {
      'api_key' => @user.single_access_token,
      'to_update' => {
        'id' => @test_plan.id,
        'product_id' => 1,            
      },
      'new_values' => {  
        'test_cases' => [2]      
      }      
    }            
    post "api/test_plans/update.json", params.to_json, request_headers    
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['test_cases'].count).to eq(1)
    expect(JSON.parse(response.body)['version']).to eq(2)
    expect(JSON.parse(response.body)['test_cases'][0]['test_case_id']).to eq(2)
    expect(JSON.parse(response.body)['test_cases'][0]['case_order']).to eq(0)   
  end
 
  it "update test case with no changes returns same version successful" do
    @test_plan = TestPlan.create(@test_plan_attr_hash) 
    @plan_case = PlanCase.create(@plan_case_attr_hash) 
    @plan_case_2 = PlanCase.create(@plan_case_attr_hash_2)          
    name = 'Test Plan'
    description = 'test plan'
    params = {
      "api_key" => @user.single_access_token,
      'name' => name,
      'product_id' => 1,      
      'description' => description      
    }
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_plans/search.json", params.to_json, request_headers    
    expect(response.status).to eq(200) 
    expect(JSON.parse(response.body)['found']).to eq(true)
    @test_plans = JSON.parse(response.body)['test_plans']
    expect(@test_plans[0]['version']).to eq(1)
    expect(@test_plans[0]['test_cases'].count).to eq(2)
    expect(@test_plans[0]['test_cases'][0]['test_case_id']).to eq(1)
    expect(@test_plans[0]['test_cases'][0]['case_order']).to eq(0)
    expect(@test_plans[0]['test_cases'][1]['test_case_id']).to eq(2)
    expect(@test_plans[0]['test_cases'][1]['case_order']).to eq(1)          
    # update with test cases
    params = {
      'api_key' => @user.single_access_token,
      'to_update' => {
        'id' => @test_plan.id,
        'product_id' => 1,            
      },
      'new_values' => {  
        'test_cases' => [1,2]      
      }      
    }            
    post "api/test_plans/update.json", params.to_json, request_headers    
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['version']).to eq(1)
    expect(JSON.parse(response.body)['test_cases'].count).to eq(2)
    expect(JSON.parse(response.body)['test_cases'][0]['test_case_id']).to eq(1)
    expect(JSON.parse(response.body)['test_cases'][0]['case_order']).to eq(0)
    expect(JSON.parse(response.body)['test_cases'][1]['test_case_id']).to eq(2)
    expect(JSON.parse(response.body)['test_cases'][1]['case_order']).to eq(1)    
  end
 
end