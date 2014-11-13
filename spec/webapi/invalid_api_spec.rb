require "webapi/webapi_spec_helper"

RSpec.describe 'Invalid API calls', :type => :request do
   
  it "routes api/other.json to webapi#invalid"  do
    params = {
      "api_key" => @user.single_access_token
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    expected = { 
      'message' => 'Invalid API endpoint.'
      }.to_json
    post "api/invalid.json", params, request_headers
    expect(response.body).to eq(expected)
    expect(response.status).to eq(400)
    post "api/invalid.xml", params, request_headers
    expect(response.status).to eq(400)     
  end 
 
  it "returns error text if not JSON or XML request" do
    expected = 'Web API requests must be JSON or XML requests'
    post "api/invalid"
    expect(response.body).to eq(expected)
    expect(response.status).to eq(400) 
  end 
  
  it "returns error if no api key provided", :skip_create_user do
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/users/search.json", {}.to_json, request_headers
    expect(response.status).to eq(400) 
  end 
  
  it "returns error if invalid api key provided" do
    params = {
      "api_key" => 'wrongkey'
    }.to_json    
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/users/search.json", params, request_headers
    expect(response.status).to eq(401) 
  end   
      
end