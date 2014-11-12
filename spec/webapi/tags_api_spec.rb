require "webapi/webapi_spec_helper"

RSpec.describe 'Tags API', :type => :request do
  
  before(:each) do
    @tag_attr_hash = FactoryGirl.attributes_for(:tag)  
  end  
   
  it "search not found" do
    params = {
      "api_key" => @user.single_access_token,
      'name' => 'tag'
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/tags/search.json", params, request_headers
    expect(JSON.parse(response.body)['found']).to eq(false)
    expect(response.status).to eq(200) 
  end
  
  it "search found" do
    @tag = Tag.create(@tag_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'name' => @tag.name
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/tags/search.json", params, request_headers
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(response.status).to eq(200) 
  end  
  
  it "create successful" do
    name = 'tag'
    params = {
      "api_key" => @user.single_access_token,
      'name' => name
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/tags/create.json", params, request_headers
    expect(JSON.parse(response.body)['name']).to eq(name)    
    expect(response.status).to eq(201) 
  end   
      
end