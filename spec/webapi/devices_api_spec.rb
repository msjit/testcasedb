require "webapi/webapi_spec_helper"

RSpec.describe 'Devices API', :type => :request do
   
  before(:each) do
    @device_attr_hash = FactoryGirl.attributes_for(:device)
    @custom_fields = [{'name' => 'custom field 1',
                       'value' => '1',
                       'type' => 'string'},
                      {'name' => 'custom field 2',
                       'value' => '2',
                       'type' => 'string'}]  
  end   
   
  it "search not found" do
    params = {
      "api_key" => @user.single_access_token,
      'id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/devices/search.json", params, request_headers
    expect(JSON.parse(response.body)['found']).to eq(false)
    expect(response.status).to eq(200) 
  end
  
  it "search found" do
    @device = Device.create(@device_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'name' => @device.name
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/devices/search.json", params, request_headers
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)).to have_key('devices')
    expect(JSON.parse(response.body)['devices'].count).to eq(1)    
    expect(response.status).to eq(200) 
  end  
  
  it "create successful" do
    name = 'Device'
    description = 'test device'   
    params = {
      "api_key" => @user.single_access_token,
      'name' => name,
      'description' => description,
      'custom_fields' => @custom_fields
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/devices/create.json", params, request_headers
    expect(JSON.parse(response.body)['name']).to eq(name)
    expect(JSON.parse(response.body)['description']).to eq(description)
    expect(JSON.parse(response.body)).to have_key('custom_fields')
    expect(JSON.parse(response.body)['custom_fields'].count).to eq(2)    
    expect(response.status).to eq(201) 
  end
  
  it "search with description not found" do
    @device = Device.create(@device_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'id' => 1,
      'description' => 'asdf'
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/devices/search.json", params, request_headers
    expect(JSON.parse(response.body)['found']).to eq(false)
    expect(response.status).to eq(200) 
  end  
  
  it "search with description found" do
    @device = Device.create(@device_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'name' => @device.name,
      'description' => @device.description 
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/devices/search.json", params, request_headers
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)).to have_key('devices')
    expect(JSON.parse(response.body)['devices'].count).to eq(1)    
    expect(response.status).to eq(200) 
  end    
    
  it "search with custom fields not found" do
    @device = Device.create(@device_attr_hash) 
    params = {
      "api_key" => @user.single_access_token,
      'id' => 1,
      'custom_fields' => @custom_fields
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/devices/search.json", params, request_headers
    expect(JSON.parse(response.body)['found']).to eq(false)
    expect(response.status).to eq(200) 
  end       

  it "search with custom fields found" do
    name = 'Device'
    description = 'test device'
    params = {
      "api_key" => @user.single_access_token,
      'name' => name,
      'description' => description,
      'custom_fields' => @custom_fields
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/devices/create.json", params, request_headers   
    expect(response.status).to eq(201)
    device = JSON.parse(response.body)
    params = {
      "api_key" => @user.single_access_token,
      'name' => device['name'],
      'description' => device['description'],
      'custom_fields' => device['custom_fields'] 
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/devices/search.json", params, request_headers
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)).to have_key('devices')
    expect(JSON.parse(response.body)['devices'].count).to eq(1)
    expect(device['custom_fields']).to eq(JSON.parse(response.body)['devices'][0]['custom_fields'])    
    expect(response.status).to eq(200) 
  end
    
  it "create same name different description successful" do
    @device = Device.create(@device_attr_hash) 
    description = 'different description'   
    params = {
      "api_key" => @user.single_access_token,
      'name' => @device.name,
      'description' => description
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/devices/create.json", params, request_headers
    expect(response.status).to eq(201) 
    expect(JSON.parse(response.body)['name']).to eq(@device.name)
    expect(JSON.parse(response.body)['description']).to eq(description)  
  end    
   
  it "create same name and description different custom fields successful" do
    @device = Device.create(@device_attr_hash)   
    params = {
      "api_key" => @user.single_access_token,
      'name' => @device.name,
      'description' => @device.description,
      'custom_fields' => @custom_fields
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/devices/create.json", params, request_headers
    expect(response.status).to eq(201) 
    expect(JSON.parse(response.body)['name']).to eq(@device.name)
    expect(JSON.parse(response.body)['description']).to eq(@device.description)
    expect(JSON.parse(response.body)).to have_key('custom_fields')
    expect(JSON.parse(response.body)['custom_fields'].count).to eq(2)    
  end     
    
end