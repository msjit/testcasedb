require "webapi/webapi_spec_helper"

RSpec.describe 'Test Cases API', :type => :request do
  
  before(:each) do
    @product = Product.create(FactoryGirl.attributes_for(:product))
    @category = Category.create(FactoryGirl.attributes_for(:category))
    @sub_category = Category.create(FactoryGirl.attributes_for(:sub_category))
    @version = Version.create(FactoryGirl.attributes_for(:version))    
    @tag = Tag.create(FactoryGirl.attributes_for(:tag))
    @tag_2 = Tag.create(FactoryGirl.attributes_for(:tag_2))
    @test_type = TestType.create(FactoryGirl.attributes_for(:test_type))    
    @test_case_attr_hash = FactoryGirl.attributes_for(:test_case) 
    @test_2_case_attr_hash = FactoryGirl.attributes_for(:test_case_2)    
  end  
   
  it "statuses return" do
    params = {
      "api_key" => @user.single_access_token
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_cases/statuses.json", params, request_headers
    expect(JSON.parse(response.body)['statuses']).to eq((I18n.t :item_status).stringify_keys)      
    expect(response.status).to eq(200) 
  end   
   
  it "types return" do
    params = {
      "api_key" => @user.single_access_token
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_cases/types.json", params, request_headers
    expect(JSON.parse(response.body)['test_types'][0]['name']).to eq(@test_type.name)   
    expect(response.status).to eq(200) 
  end    
   
  it "search not found" do
    params = {
      "api_key" => @user.single_access_token,
      'category' => 'Test Category',
      'product_id' => 1,
      'test_case_name' => 'Test Case'
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_cases/search.json", params, request_headers
    expect(JSON.parse(response.body)['found']).to eq(false)
    expect(response.status).to eq(200) 
  end
  
  it "search found" do
    @test_case = TestCase.create(@test_case_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'category' => @category.name,
      'product_id' => 1,
      'test_case_name' => 'Test Case'
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_cases/search.json", params, request_headers
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(response.status).to eq(200) 
  end  
 
  it "create fails with wrong product" do
    name = 'Test Case'
    params = {
      "api_key" => @user.single_access_token,
      'test_case_name' => name,
      'category' => @category.name,
      'product_name' => 'nonexistent product',      
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_cases/create.json", params, request_headers
    expect(response.status).to eq(400) 
  end  
  
  it "create fails with wrong category" do
    name = 'Test Case'
    category = 'Nonexistent Category'
    params = {
      "api_key" => @user.single_access_token,
      'test_case_name' => name,
      'category' => category,
      'product_id' => 1,      
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_cases/create.json", params, request_headers
    expect(response.status).to eq(400) 
  end  
  
  it "create fails with bad user id" do
    name = 'Test Case'
    params = {
      "api_key" => @user.single_access_token,
      'test_case_name' => name,
      'category' => @category.name,      
      'product_id' => 1,
      'created_by_id' => 2
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_cases/create.json", params, request_headers
    expect(response.status).to eq(400) 
  end  
  
  it "create fails with bad test type" do
    name = 'Test Case'
    params = {
      "api_key" => @user.single_access_token,
      'test_case_name' => name,
      'category' => @category.name,      
      'product_id' => 1,
      'test_type_id' => 2
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_cases/create.json", params, request_headers
    expect(response.status).to eq(400) 
  end  
  
  it "create successful" do
    name = 'Test Case'
    description = 'test case'
    custom_fields = {
      'field 1'=> {'name' => 'custom field 1',
                   'value' => '1',
                   'type' => 'string'},
      'field 2'=> {'name' => 'custom field 2',
                   'value' => '2',
                   'type' => 'string'}                   
    }
    params = {
      "api_key" => @user.single_access_token,
      'test_case_name' => name,
      'category' => @category.name,
      'product_id' => 1,      
      'description' => description,
      'custom_fields' => custom_fields,
      'tags' => [@tag.name, @tag_2.name, 'tag 3']
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_cases/create.json", params, request_headers 
    expect(response.status).to eq(201) 
    expect(JSON.parse(response.body)['category']).to eq(@category.name) 
    expect(JSON.parse(response.body)['id']).to eq(1)  
    expect(JSON.parse(response.body)['parent_id']).to eq(nil) 
    expect(JSON.parse(response.body)['custom_fields'].count).to eq(2)
    expect(JSON.parse(response.body)['tags'].count).to eq(3)
    expect(JSON.parse(response.body)['tags'][0]['id']).to eq(@tag.id) 
    expect(JSON.parse(response.body)['tags'][2]['name']).to eq('tag 3') 
  end    

  it "create in sub category successful" do
    name = 'Test Case'
    description = 'test case'
    category = '%s/%s' %[@category.name, @sub_category.name]
    custom_fields = {
      'field 1'=> {'name' => 'custom field 1',
                   'value' => '1',
                   'type' => 'string'},
      'field 2'=> {'name' => 'custom field 2',
                   'value' => '2',
                   'type' => 'string'}                   
    }
    params = {
      "api_key" => @user.single_access_token,
      'test_case_name' => name,
      'category' => category,
      'product_id' => 1,      
      'description' => description,
      'custom_fields' => custom_fields
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_cases/create.json", params, request_headers
    expect(JSON.parse(response.body)['category']).to eq(category) 
    expect(JSON.parse(response.body)['id']).to eq(1)  
    expect(JSON.parse(response.body)['parent_id']).to eq(nil)  
    expect(response.status).to eq(201) 
  end
  
  it "create new version successful" do
    name = 'Test Case'
    description = 'test case'
    custom_fields = {
      'field 1'=> {'name' => 'custom field 1',
                   'value' => '1',
                   'type' => 'string'},
      'field 2'=> {'name' => 'custom field 2',
                   'value' => '2',
                   'type' => 'string'}                   
    }
    params = {
      "api_key" => @user.single_access_token,
      'test_case_name' => name,
      'category' => @category.name,
      'product_id' => 1,      
      'description' => description,
      'custom_fields' => custom_fields,
      'tags' => [@tag.name] 
    }
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_cases/create.json", params.to_json, request_headers 
    expect(JSON.parse(response.body)['category']).to eq(@category.name) 
    expect(JSON.parse(response.body)['id']).to eq(1)  
    expect(JSON.parse(response.body)['parent_id']).to eq(nil)  
    expect(response.status).to eq(201)
    # new version
    params['new_version'] = true
    post "api/test_cases/create.json", params.to_json, request_headers
    expect(response.status).to eq(201)
    expect(JSON.parse(response.body)['version']).to eq(2) 
    expect(JSON.parse(response.body)['custom_fields'].count).to eq(2)
    expect(JSON.parse(response.body)['tags'].count).to eq(1)
    expect(JSON.parse(response.body)['tags'][0]['id']).to eq(@tag.id)
  end 
   
  it "update successful" do
    @test_case = TestCase.create(@test_case_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'test_case_name' => @test_case.name,
      'category' => @category.name,
      'product_id' => 1,      
      'description' => @test_case.description,
      'tags' => [@tag.name]
    }
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_cases/search.json", params.to_json, request_headers
    expect(response.status).to eq(200) 
    expect(JSON.parse(response.body)['found']).to eq(true)    
    expect(JSON.parse(response.body)['name']).to eq(@test_case.name)
    expect(JSON.parse(response.body)['description']).to eq(@test_case.description)
    expect(JSON.parse(response.body)['version']).to eq(@test_case.version)
    expect(JSON.parse(response.body)['parent_id']).to eq(@test_case.parent_id)
    expect(JSON.parse(response.body)['product']).to eq(@test_case.product.name)
    expect(JSON.parse(response.body)['product_id']).to eq(@test_case.product.id)     
    expect(JSON.parse(response.body)['category']).to eq(@category.name)
    expect(JSON.parse(response.body)['category_id']).to eq(@category.id)    
    expect(JSON.parse(response.body)['tags']).to eq([])
    expect(JSON.parse(response.body)['custom_fields']).to eq([])
    expect(JSON.parse(response.body)['status']).to eq((I18n.t :item_status)[@test_case.status])       
    # update
    name = 'Updated name'
    description = 'updated description'
    category = "%s/%s" %[@category.name, @sub_category.name]
    version = 5
    params['overwrite_custom_fields'] = true
    custom_fields = {
      'field 1'=> {'name' => 'custom field 1',
                   'value' => '1',
                   'type' => 'string'},
      'field 2'=> {'name' => 'custom field 2',
                   'value' => '2',
                   'type' => 'string'}                   
    }     
    params = {
      'api_key' => @user.single_access_token,
      'to_update' => {
        'test_case_name' => @test_case.name,
        'category' => @category.name,
        'product_id' => 1,            
      },
      'new_values' => {  
        'test_case_name' => name,
        'category' => category,
        'product_id' => 1, 
        'description' => description,
        'custom_fields' => custom_fields,
        'overwrite_custom_fields' => true,
        'tags' => [@tag.name, @tag_2.name]        
      },      
    }      
    post "api/test_cases/update.json", params.to_json, request_headers    
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['name']).to eq(name)
    expect(JSON.parse(response.body)['description']).to eq(description)
    expect(JSON.parse(response.body)['version']).to eq(@test_case.version)
    expect(JSON.parse(response.body)['parent_id']).to eq(@test_case.parent_id)
    expect(JSON.parse(response.body)['product']).to eq(@test_case.product.name)
    expect(JSON.parse(response.body)['product_id']).to eq(@test_case.product.id)     
    expect(JSON.parse(response.body)['category']).to eq(category)
    expect(JSON.parse(response.body)['category_id']).to eq(@sub_category.id)    
    expect(JSON.parse(response.body)['custom_fields'].count).to eq(2)
    expect(JSON.parse(response.body)['custom_fields'][0]).to eq(custom_fields['field 1'])
    expect(JSON.parse(response.body)['custom_fields'][1]).to eq(custom_fields['field 2'])
    expect(JSON.parse(response.body)['tags'].count).to eq(2)
    expect(JSON.parse(response.body)['tags'][1]['id']).to eq(@tag_2.id)
    expect(JSON.parse(response.body)['status']).to eq((I18n.t :item_status)[@test_case.status])    
  end    
  
  it "create multiple successful" do
    params = {
      "api_key" => @user.single_access_token,
      'test_cases' => {
        0 => {'test_case_name' => 'case 1',
              'category' => @category.name,
              'product_id' => 1},
        1 => {'test_case_name' => 'case 2',
              'category' => @category.name,
              'product_id' => 1}                   
      }
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_cases/create.json", params, request_headers 
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['test_cases'].count).to eq(2)
    expect(JSON.parse(response.body)['test_cases'][0]['name']).to eq('case 1')
    expect(JSON.parse(response.body)['test_cases'][1]['name']).to eq('case 2')
  end     
  
  it "update multiple successful" do
    @test_case = TestCase.create(@test_case_attr_hash)
    @test_case_2 = TestCase.create(@test_2_case_attr_hash)
    updated_name_1 = 'updated name 1'
    updated_description_1 = 'updated description 1'
    updated_name_2 = 'updated name 2'
    updated_description_2 = 'updated description 2'    
    params = {
      "api_key" => @user.single_access_token,
      'test_cases' => {
        0 => {
          'to_update' => {
            'test_case_name' => @test_case.name,
            'category' => @category.name,
            'product_id' => 1,            
          },
          'new_values' => {  
            'test_case_name' => updated_name_1,
            'description' => updated_description_1,        
          }                 
        },
        1 => {
          'to_update' => {
            'test_case_name' => @test_case_2.name,
            'category' => @category.name,
            'product_id' => 1,            
          },
          'new_values' => {  
            'test_case_name' => updated_name_2,
            'description' => updated_description_2,        
          }                 
        }        
      }
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/test_cases/update.json", params, request_headers 
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['test_cases'].count).to eq(2)
    expect(JSON.parse(response.body)['test_cases'][0]['name']).to eq(updated_name_1)
    expect(JSON.parse(response.body)['test_cases'][0]['description']).to eq(updated_description_1)
    expect(JSON.parse(response.body)['test_cases'][1]['name']).to eq(updated_name_2)
    expect(JSON.parse(response.body)['test_cases'][1]['description']).to eq(updated_description_2)
  end   
     
end