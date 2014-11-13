require "webapi/webapi_spec_helper"

RSpec.describe 'Users API', :type => :request do
 
  it "search not found" do
    params = {
      "api_key" => @user.single_access_token,
      'username' => 'testuser',
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/users/search.json", params, request_headers
    expect(JSON.parse(response.body)['found']).to eq(false)
    expect(response.status).to eq(200) 
  end
  
  it "search found" do
    params = {
      "api_key" => @user.single_access_token,
      'username' => @user.username
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/users/search.json", params, request_headers
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)).to have_key('users')
    expect(JSON.parse(response.body)['users'].count).to eq(1)
    expect(response.status).to eq(200) 
  end  
  
  it "roles return" do
    params = {
      "api_key" => @user.single_access_token
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/users/roles.json", params, request_headers
    roles = {'message' => (I18n.t :user_roles)}.to_json
    expect(response.body).to eq(roles)   
    expect(response.status).to eq(200) 
  end   
      
end