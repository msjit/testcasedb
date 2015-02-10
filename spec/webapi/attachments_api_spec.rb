require "webapi/webapi_spec_helper"

RSpec.describe 'Attachments API', :focus, :type => :request do
  
  before(:each) do
    @upload_attr_hash = FactoryGirl.attributes_for(:upload)     
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
    post "api/attachments/search.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['found']).to eq(false) 
  end

  it "search by id found" do
    #Image.new :photo => File.new(Rails.root + 'spec/fixtures/images/rails.png')
    @upload = Upload.create(@upload_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/search.json", params, request_headers
    expect(response.status).to eq(200)     
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['attachments'].count).to eq(1)
    expect(JSON.parse(response.body)['attachments'][0]['id']).to eq(@upload.id)
    expect(JSON.parse(response.body)['attachments'][0]['description']).to eq(@upload.description)
    expect(JSON.parse(response.body)['attachments'][0]['parent_id']).to eq(@upload.uploadable_id)
    expect(JSON.parse(response.body)['attachments'][0]['parent_type']).to eq(@upload.uploadable_type)
    expect(JSON.parse(response.body)['attachments'][0]['file_name']).to eq(@upload.upload_file_name)
    expect(JSON.parse(response.body)['attachments'][0]['content_type']).to eq(@upload.upload_content_type)
    expect(JSON.parse(response.body)['attachments'][0]['size']).to eq(@upload.upload_file_size)
    expect(JSON.parse(response.body)['attachments'][0]['size']).to eq(File.size(Rails.root.join('spec/test_files/attachments/images/snake.png')))
    expect(JSON.parse(response.body)['attachments'][0]['data']).to eq(nil)
  end 
 
   it "download not found" do
    params = {
      "api_key" => @user.single_access_token,
      'id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/download.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['found']).to eq(false) 
  end
 
   it "download by id successful" do
    @upload = Upload.create(@upload_attr_hash)
    params = {
      "api_key" => @user.single_access_token,
      'id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/download.json", params, request_headers
    expect(response.status).to eq(200)     
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['attachments'].count).to eq(1)
    expect(JSON.parse(response.body)['attachments'][0]['id']).to eq(@upload.id)
    expect(JSON.parse(response.body)['attachments'][0]['description']).to eq(@upload.description)
    expect(JSON.parse(response.body)['attachments'][0]['parent_id']).to eq(@upload.uploadable_id)
    expect(JSON.parse(response.body)['attachments'][0]['parent_type']).to eq(@upload.uploadable_type)
    expect(JSON.parse(response.body)['attachments'][0]['file_name']).to eq(@upload.upload_file_name)
    expect(JSON.parse(response.body)['attachments'][0]['content_type']).to eq(@upload.upload_content_type)
    expect(JSON.parse(response.body)['attachments'][0]['size']).to eq(@upload.upload_file_size)
    expect(JSON.parse(response.body)['attachments'][0]['size']).to eq(File.size(Rails.root.join('spec/test_files/attachments/images/snake.png')))
    expect(JSON.parse(response.body)['attachments'][0]['data']).to eq(Base64.encode64(File.read(Rails.root.join('spec/test_files/attachments/images/snake.png'))))
  end
 
   it "upload png successful" do
    description = 'test description'
    file_name = 'test.png'
    content_type = 'image/png'
    parent_id = 1
    parent_type = 'Result'
    params = {
      'api_key' => @user.single_access_token,
      'description' => description,
      'file_name' => file_name,
      'parent_id' => parent_id,
      'parent_type' => parent_type,
      'data' => Base64.encode64(File.read(Rails.root.join('spec/test_files/attachments/images/snake.png')))
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/upload.json", params, request_headers
    expect(response.status).to eq(201)    
    expect(JSON.parse(response.body)['id']).to eq(1)
    expect(JSON.parse(response.body)['description']).to eq(description)
    expect(JSON.parse(response.body)['file_name']).to eq(file_name)
    expect(JSON.parse(response.body)['content_type']).to eq(content_type)
    expect(JSON.parse(response.body)['size']).to eq(File.size(Rails.root.join('spec/test_files/attachments/images/snake.png')))
    expect(JSON.parse(response.body)['parent_id']).to eq(parent_id)
    expect(JSON.parse(response.body)['parent_type']).to eq(parent_type)
  end 

   it "upload jpg successful" do
    description = 'test description'
    file_name = 'test.jpg'
    content_type = 'image/jpeg'
    parent_id = 1
    parent_type = 'Result'
    params = {
      'api_key' => @user.single_access_token,
      'description' => description,
      'file_name' => file_name,
      'parent_id' => parent_id,
      'parent_type' => parent_type,
      'data' => Base64.encode64(File.read(Rails.root.join('spec/test_files/attachments/images/snake.jpg')))
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/upload.json", params, request_headers
    expect(response.status).to eq(201)    
    expect(JSON.parse(response.body)['id']).to eq(1)
    expect(JSON.parse(response.body)['description']).to eq(description)
    expect(JSON.parse(response.body)['file_name']).to eq(file_name)
    expect(JSON.parse(response.body)['content_type']).to eq(content_type)
    expect(JSON.parse(response.body)['size']).to eq(File.size(Rails.root.join('spec/test_files/attachments/images/snake.jpg')))
    expect(JSON.parse(response.body)['parent_id']).to eq(parent_id)
    expect(JSON.parse(response.body)['parent_type']).to eq(parent_type)
  end 
 
  it "update not found" do
    params = {
      "api_key" => @user.single_access_token,
      'id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/update.json", params, request_headers
    expect(response.status).to eq(400)
    expect(JSON.parse(response.body)['message']).to eq('TODO') 
  end

  it "delete not found" do
    params = {
      "api_key" => @user.single_access_token,
      'id' => 1
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/delete.json", params, request_headers
    expect(response.status).to eq(400)
    expect(JSON.parse(response.body)['message']).to eq('TODO')
  end
 
  after(:each) do
    # remove test uploads directory
    FileUtils.rm_rf(Dir["#{Rails.root}/spec/test_files/test"])
  end
end