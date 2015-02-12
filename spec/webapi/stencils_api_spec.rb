require "webapi/webapi_spec_helper"

RSpec.describe 'Stencils API', :type => :request do
  
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
    @stencil_test_plan_attr_hash = FactoryGirl.attributes_for(:stencil_test_plan)
    @stencil_test_plan_attr_hash_2 = FactoryGirl.attributes_for(:stencil_test_plan_2)
  end  
   
  it "statuses return" do
    params = {
      "api_key" => @user.single_access_token
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/stencils/statuses.json", params, request_headers
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
    post "api/stencils/search.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['found']).to eq(false)     
  end
  
  it "search found" do
    @stencil = Stencil.create(@stencil_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'product_id' => 1,
      'id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/stencils/search.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['stencils'].count).to eq(1)
    expect(JSON.parse(response.body)['stencils'][0]['test_plans'].count).to eq(0)    
  end  
 
  it "create fails with wrong product" do
    name = 'Stencil'
    params = {
      "api_key" => @user.single_access_token,
      'name' => name,
      'product_name' => 'nonexistent product',      
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/stencils/create.json", params, request_headers  
    expect(response.status).to eq(400) 
  end 
  
  it "create fails with bad user id" do
    name = 'Stencil'
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
    post "api/stencils/create.json", params, request_headers
    expect(response.status).to eq(400) 
  end  
 
  it "create successful" do
    name = 'Test Stencil'
    description = 'test stencil'
    params = {
      "api_key" => @user.single_access_token,
      'name' => name,
      'product_id' => 1,      
      'description' => description
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/stencils/create.json", params, request_headers      
    expect(response.status).to eq(201)
    expect(JSON.parse(response.body)['id']).to eq(1)  
    expect(JSON.parse(response.body)['parent_id']).to eq(nil)
    expect(JSON.parse(response.body)['test_plans'].count).to eq(0)
  end
  
  it "create new version successful" do
    name = 'Test Stencil'
    description = 'test stencil'
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
    post "api/stencils/create.json", params.to_json, request_headers
    expect(response.status).to eq(201) 
    expect(JSON.parse(response.body)['id']).to eq(1)  
    expect(JSON.parse(response.body)['parent_id']).to eq(nil)
    expect(JSON.parse(response.body)['test_plans'].count).to eq(0)      
    # new version
    params['new_version'] = true
    post "api/stencils/create.json", params.to_json, request_headers
    expect(response.status).to eq(201)
    expect(JSON.parse(response.body)['version']).to eq(2) 
    expect(JSON.parse(response.body)['test_plans'].count).to eq(0)
  end 

  it "update successful" do
    @stencil = Stencil.create(@stencil_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'id' => @stencil.id,
      'product_id' => @product.id
    }
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/stencils/search.json", params.to_json, request_headers 
    expect(response.status).to eq(200) 
    expect(JSON.parse(response.body)['found']).to eq(true)   
    expect(JSON.parse(response.body)['stencils'].count).to eq(1)
    expect(JSON.parse(response.body)['stencils'][0]['test_plans'].count).to eq(0) 
    @stencils = JSON.parse(response.body)['stencils'][0]
    expect(@stencils['name']).to eq(@stencil.name)
    expect(@stencils['description']).to eq(@stencil.description)
    expect(@stencils['version']).to eq(@stencil.version)
    expect(@stencils['parent_id']).to eq(@stencil.parent_id)
    expect(@stencils['product_id']).to eq(@stencil.product.id)
    expect(@stencils['status']).to eq((I18n.t :item_status)[@stencil.status])
    expect(@stencils['test_plans'].count).to eq(0)     
    # update
    name = 'Updated name'
    description = 'updated description'
    version = 5     
    params = {
      'api_key' => @user.single_access_token,
      'to_update' => {
        'id' => @stencil.id,
        'product_id' => @product.id,            
      },
      'new_values' => {  
        'name' => name,
        'product_id' => 1, 
        'description' => description      
      },      
    }      
    post "api/stencils/update.json", params.to_json, request_headers   
    @stencil.reload 
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['name']).to eq(name)
    expect(JSON.parse(response.body)['description']).to eq(description)
    expect(JSON.parse(response.body)['version']).to eq(@stencil.version)
    expect(JSON.parse(response.body)['parent_id']).to eq(@stencil.parent_id)
    expect(JSON.parse(response.body)['product_id']).to eq(@stencil.product.id)
    expect(JSON.parse(response.body)['status']).to eq((I18n.t :item_status)[@stencil.status])
    expect(JSON.parse(response.body)['test_plans'].count).to eq(0)    
  end 

  it "create with test plans successful" do   
    name = 'Test Stencil'
    description = 'test stencil'
    params = {
      "api_key" => @user.single_access_token,
      'name' => name,
      'product_id' => 1,
      'description' => description,
      'test_plans' => [{'id' => @test_plan.id, 'device_id' => @device.id},
                       {'id' => @test_plan_2.id, 'device_id' => @device_2.id}]
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/stencils/create.json", params, request_headers
    expect(response.status).to eq(201)
    expect(JSON.parse(response.body)['test_plans'].count).to eq(2)
    expect(JSON.parse(response.body)['test_plans'][0]['test_plan_id']).to eq(@test_plan.id)
    expect(JSON.parse(response.body)['test_plans'][0]['device_id']).to eq(@device.id)
    expect(JSON.parse(response.body)['test_plans'][1]['test_plan_id']).to eq(@test_plan_2.id)
    expect(JSON.parse(response.body)['test_plans'][1]['device_id']).to eq(@device_2.id)
  end

  it "update with test plans successful" do
    @stencil = Stencil.create(@stencil_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'name' => @stencil.name,
      'product_id' => 1,      
      'description' => @stencil.description      
    }
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/stencils/search.json", params.to_json, request_headers    
    expect(response.status).to eq(200) 
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['stencils'][0]['test_plans'].count).to eq(0)
    # update with test cases
    params = {
      'api_key' => @user.single_access_token,
      'to_update' => {
        'id' => @stencil.id,
        'product_id' => 1,            
      },
      'new_values' => {  
        'test_plans' => [{'id' => @test_plan.id, 'device_id' => @device.id},
                         {'id' => @test_plan_2.id, 'device_id' => @device_2.id}]     
      }      
    }            
    post "api/stencils/update.json", params.to_json, request_headers    
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['test_plans'].count).to eq(2)
    expect(JSON.parse(response.body)['version']).to eq(1)
    expect(JSON.parse(response.body)['test_plans'][0]['test_plan_id']).to eq(@test_plan.id)
    expect(JSON.parse(response.body)['test_plans'][0]['plan_order']).to eq(0)
    expect(JSON.parse(response.body)['test_plans'][1]['test_plan_id']).to eq(@test_plan_2.id)
    expect(JSON.parse(response.body)['test_plans'][1]['plan_order']).to eq(1)    
  end  

  it "update test plan order successful" do
    @stencil = Stencil.create(@stencil_attr_hash) 
    @stencil_test_plan = StencilTestPlan.create(@stencil_test_plan_attr_hash) 
    @stencil_test_plan_2 = StencilTestPlan.create(@stencil_test_plan_attr_hash_2)          
    params = {
      "api_key" => @user.single_access_token,
      'name' => @stencil.name,
      'product_id' => 1,      
      'description' => @stencil.description      
    }
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/stencils/search.json", params.to_json, request_headers    
    expect(response.status).to eq(200) 
    expect(JSON.parse(response.body)['found']).to eq(true)
    @stencils = JSON.parse(response.body)['stencils'][0]    
    expect(@stencils['test_plans'].count).to eq(2)
    expect(@stencils['version']).to eq(1)
    expect(@stencils['test_plans'][0]['test_plan_id']).to eq(@test_plan.id)
    expect(@stencils['test_plans'][0]['plan_order']).to eq(0)
    expect(@stencils['test_plans'][1]['test_plan_id']).to eq(@test_plan_2.id)
    expect(@stencils['test_plans'][1]['plan_order']).to eq(1)    
    # update with test plans
    params = {
      'api_key' => @user.single_access_token,
      'to_update' => {
        'id' => @stencil.id,
        'product_id' => 1,            
      },
      'new_values' => {  
        'test_plans' => [{'id' => @test_plan_2.id, 'device_id' => @device_2.id},
                         {'id' => @test_plan.id, 'device_id' => @device.id}]      
      }      
    }            
    post "api/stencils/update.json", params.to_json, request_headers    
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['test_plans'].count).to eq(2)
    expect(JSON.parse(response.body)['version']).to eq(2)
    expect(JSON.parse(response.body)['test_plans'][0]['test_plan_id']).to eq(@test_plan_2.id)
    expect(JSON.parse(response.body)['test_plans'][0]['plan_order']).to eq(0)
    expect(JSON.parse(response.body)['test_plans'][1]['test_plan_id']).to eq(@test_plan.id)
    expect(JSON.parse(response.body)['test_plans'][1]['plan_order']).to eq(1)     
  end
 
  it "update test plan removing one successful"  do
    @stencil = Stencil.create(@stencil_attr_hash) 
    @stencil_test_plan = StencilTestPlan.create(@stencil_test_plan_attr_hash) 
    @stencil_test_plan_2 = StencilTestPlan.create(@stencil_test_plan_attr_hash_2)          
    params = {
      "api_key" => @user.single_access_token,
      'name' => @stencil.name,
      'product_id' => 1,      
      'description' => @stencil.description      
    }
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/stencils/search.json", params.to_json, request_headers    
    expect(response.status).to eq(200) 
    expect(JSON.parse(response.body)['found']).to eq(true)
    @stencils = JSON.parse(response.body)['stencils'][0]    
    expect(@stencils['test_plans'].count).to eq(2)
    expect(@stencils['version']).to eq(1)
    expect(@stencils['test_plans'][0]['test_plan_id']).to eq(@test_plan.id)
    expect(@stencils['test_plans'][0]['plan_order']).to eq(0)
    expect(@stencils['test_plans'][1]['test_plan_id']).to eq(@test_plan_2.id)
    expect(@stencils['test_plans'][1]['plan_order']).to eq(1)   
    # update with test plans
    params = {
      'api_key' => @user.single_access_token,
      'to_update' => {
        'id' => @stencil.id,
        'product_id' => 1,            
      },
      'new_values' => {  
        'test_plans' => [{'id' => @test_plan_2.id, 'device_id' => @device_2.id}]      
      }      
    }            
    post "api/stencils/update.json", params.to_json, request_headers    
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['test_plans'].count).to eq(1)
    expect(JSON.parse(response.body)['version']).to eq(2)
    expect(JSON.parse(response.body)['test_plans'][0]['test_plan_id']).to eq(@test_plan_2.id)
    expect(JSON.parse(response.body)['test_plans'][0]['plan_order']).to eq(0)    
  end

  it "update test plan with no changes returns same version successful" do
    @stencil = Stencil.create(@stencil_attr_hash) 
    @stencil_test_plan = StencilTestPlan.create(@stencil_test_plan_attr_hash) 
    @stencil_test_plan_2 = StencilTestPlan.create(@stencil_test_plan_attr_hash_2)          
    params = {
      "api_key" => @user.single_access_token,
      'name' => @stencil.name,
      'product_id' => 1,      
      'description' => @stencil.description      
    }
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/stencils/search.json", params.to_json, request_headers    
    expect(response.status).to eq(200) 
    expect(JSON.parse(response.body)['found']).to eq(true)
    @stencils = JSON.parse(response.body)['stencils'][0]    
    expect(@stencils['test_plans'].count).to eq(2)
    expect(@stencils['version']).to eq(1)
    expect(@stencils['test_plans'][0]['test_plan_id']).to eq(@test_plan.id)
    expect(@stencils['test_plans'][0]['plan_order']).to eq(0)
    expect(@stencils['test_plans'][1]['test_plan_id']).to eq(@test_plan_2.id)
    expect(@stencils['test_plans'][1]['plan_order']).to eq(1)   
    # update with test plans
    params = {
      'api_key' => @user.single_access_token,
      'to_update' => {
        'id' => @stencil.id,
        'product_id' => 1,            
      },
      'new_values' => {  
        'test_plans' => [{'device_id' => @stencil_test_plan.device_id, 'id' => @stencil_test_plan.test_plan_id},
                         {'id' => @stencil_test_plan_2.test_plan_id, 'device_id' => @stencil_test_plan_2.device_id}]     
      }      
    }            
    post "api/stencils/update.json", params.to_json, request_headers    
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['version']).to eq(1)
    expect(JSON.parse(response.body)['test_plans'][0]['test_plan_id']).to eq(@test_plan.id)
    expect(JSON.parse(response.body)['test_plans'][0]['plan_order']).to eq(0)
    expect(JSON.parse(response.body)['test_plans'][1]['test_plan_id']).to eq(@test_plan_2.id)
    expect(JSON.parse(response.body)['test_plans'][1]['plan_order']).to eq(1)    
  end

  it "update without creating new version successful" do
    @stencil = Stencil.create(@stencil_attr_hash) 
    @stencil_test_plan = StencilTestPlan.create(@stencil_test_plan_attr_hash) 
    @stencil_test_plan_2 = StencilTestPlan.create(@stencil_test_plan_attr_hash_2)          
    params = {
      "api_key" => @user.single_access_token,
      'name' => @stencil.name,
      'product_id' => 1,      
      'description' => @stencil.description      
    }
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/stencils/search.json", params.to_json, request_headers    
    expect(response.status).to eq(200) 
    expect(JSON.parse(response.body)['found']).to eq(true)
    @stencils = JSON.parse(response.body)['stencils'][0]    
    expect(@stencils['test_plans'].count).to eq(2)
    expect(@stencils['version']).to eq(1)
    expect(@stencils['test_plans'][0]['test_plan_id']).to eq(@test_plan.id)
    expect(@stencils['test_plans'][0]['plan_order']).to eq(0)
    expect(@stencils['test_plans'][1]['test_plan_id']).to eq(@test_plan_2.id)
    expect(@stencils['test_plans'][1]['plan_order']).to eq(1)   
    # update with test cases
    params = {
      'api_key' => @user.single_access_token,
      'to_update' => {
        'id' => @stencil.id,
        'product_id' => 1,            
      },
      'new_values' => {  
        'test_plans' => [{'id' => @test_plan_2.id, 'device_id' => @device_2.id}]              
      },
      'new_version' => false
    }            
    post "api/stencils/update.json", params.to_json, request_headers    
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['test_plans'].count).to eq(1)
    expect(JSON.parse(response.body)['version']).to eq(1)
    expect(JSON.parse(response.body)['test_plans'][0]['test_plan_id']).to eq(@test_plan_2.id)
    expect(JSON.parse(response.body)['test_plans'][0]['plan_order']).to eq(0)   
  end

end