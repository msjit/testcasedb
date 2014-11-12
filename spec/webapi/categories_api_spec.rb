require "webapi/webapi_spec_helper"

RSpec.describe 'Categories API', :type => :request do
  
  before(:each) do
    @product = Product.create(FactoryGirl.attributes_for(:product))
    @category_attr_hash = FactoryGirl.attributes_for(:category)
    @sub_category_attr_hash = FactoryGirl.attributes_for(:sub_category)         
  end  
   
  it "search not found" do
    params = {
      "api_key" => @user.single_access_token,
      'category' => 'Test Category',
      'product_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/categories/search.json", params, request_headers
    expect(JSON.parse(response.body)['found']).to eq(false)
    expect(response.status).to eq(200) 
  end
  
  it "search found" do
    @category = Category.create(@category_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'category' => 'Test Category',
      'product_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/categories/search.json", params, request_headers
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(response.status).to eq(200) 
  end
  
  it "search sub category found" do
    @category = Category.create(@category_attr_hash)
    @sub_category = Category.create(@sub_category_attr_hash)
    full_category = '%s/%s' %[@category.name, @sub_category.name]
    params = {
      "api_key" => @user.single_access_token,
      'category' => full_category,
      'product_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/categories/search.json", params, request_headers
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['category']).to eq(full_category) 
    expect(JSON.parse(response.body)['id']).to eq(@sub_category.id) 
    expect(JSON.parse(response.body)['category_hierarchy'].count).to eq(2)    
    expect(response.status).to eq(200) 
  end     
  
  it "create successful" do
    category = 'Tests'
    params = {
      "api_key" => @user.single_access_token,
      'category' => category,
      'product_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/categories/create.json", params, request_headers
    expect(JSON.parse(response.body)['category']).to eq(category) 
    expect(JSON.parse(response.body)['id']).to eq(1)  
    expect(JSON.parse(response.body)['parent_id']).to eq(nil)
    expect(JSON.parse(response.body)['category_hierarchy'].count).to eq(1)   
    expect(response.status).to eq(201) 
  end
  
  it "create sub category successful" do
    @category = Category.create(@category_attr_hash)
    category = '%s/Tests' %[@category.name]
    params = {
      "api_key" => @user.single_access_token,
      'category' => category,
      'product_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/categories/create.json", params, request_headers
    expect(JSON.parse(response.body)['category']).to eq(category) 
    expect(JSON.parse(response.body)['id']).to eq(2)
    expect(JSON.parse(response.body)['category_hierarchy'].count).to eq(2)  
    expect(response.status).to eq(201) 
  end      
      
end