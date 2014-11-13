require "webapi/webapi_spec_helper"

RSpec.describe 'Products API', :type => :request do
 
  it "search not found" do
    params = {
      "api_key" => @user.single_access_token,
      'id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/products/search.json", params, request_headers
    expect(JSON.parse(response.body)['found']).to eq(false)
    expect(response.status).to eq(200) 
  end
  
  it "search found" do
    @product_attr_hash = FactoryGirl.attributes_for(:product) 
    @product = Product.create(@product_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'id' => 1
      #'name' => "Product"
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/products/search.json", params, request_headers
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)).to have_key('products')
    expect(JSON.parse(response.body)['products'].count).to eq(1)
    expect(response.status).to eq(200) 
  end  
  
  it "create successful" do
    name = 'Product'
    description = 'test description'
    params = {
      "api_key" => @user.single_access_token,
      'name' => name,
      'description' => description
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/products/create.json", params, request_headers
    expect(JSON.parse(response.body)['name']).to eq(name)
    expect(JSON.parse(response.body)['description']).to eq(description)    
    expect(response.status).to eq(201) 
  end   
      
end