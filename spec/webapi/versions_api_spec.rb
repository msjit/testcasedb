require "webapi/webapi_spec_helper"

RSpec.describe 'Versions API', :type => :request do
  
  before(:each) do
    @product_attr_hash = FactoryGirl.attributes_for(:product) 
    @product = Product.create(@product_attr_hash)
    @version_attr_hash = FactoryGirl.attributes_for(:version) 
    @version_attr_hash_2 = FactoryGirl.attributes_for(:version_2)  
  end  
   
  it "search not found" do
    params = {
      "api_key" => @user.single_access_token,
      'version' => '1.0',
      'product_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/versions/search.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['found']).to eq(false) 
  end

  it "search by version found" do
    @version = Version.create(@version_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'version' => '1.0'
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/versions/search.json", params, request_headers
    expect(response.status).to eq(200)     
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['versions'].count).to eq(1)
    expect(JSON.parse(response.body)['versions'][0]['id']).to eq(@version.id)
  end 
  
  it "search by id found" do
    @version = Version.create(@version_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/versions/search.json", params, request_headers
    expect(response.status).to eq(200)     
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['versions'].count).to eq(1)
    expect(JSON.parse(response.body)['versions'][0]['id']).to eq(@version.id)
  end   
  
  it "search multiple by product_id found" do
    @version = Version.create(@version_attr_hash)
    @version_2 = Version.create(@version_attr_hash_2)
    params = {
      "api_key" => @user.single_access_token,
      'product_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/versions/search.json", params, request_headers
    expect(response.status).to eq(200)     
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['versions'].count).to eq(2)
    expect(JSON.parse(response.body)['versions'][0]['id']).to eq(@version.id)
    expect(JSON.parse(response.body)['versions'][1]['id']).to eq(@version_2.id)
  end  
  
  it "create successful" do
    version = '1.0'
    description = 'first version'
    params = {
      "api_key" => @user.single_access_token,
      'version' => version,
      'description' => description,
      'product_id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/versions/create.json", params, request_headers
    expect(response.status).to eq(201)
    expect(JSON.parse(response.body)['version']).to eq(version)
    expect(JSON.parse(response.body)['description']).to eq(description)     
  end   
      
end