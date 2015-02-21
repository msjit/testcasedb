require "webapi/webapi_spec_helper"

def verify_attachment(factory_girl_object, attachment, file_path)  
  expect(attachment['id']).to eq(factory_girl_object.id)
  expect(attachment['description']).to eq(factory_girl_object.description)
  expect(attachment['parent_id']).to eq(factory_girl_object.uploadable_id)
  expect(attachment['parent_type']).to eq(factory_girl_object.uploadable_type)
  expect(attachment['file_name']).to eq(factory_girl_object.upload_file_name)
  expect(attachment['content_type']).to eq(factory_girl_object.upload_content_type)
  expect(attachment['size']).to eq(factory_girl_object.upload_file_size)
  expect(attachment['size']).to eq(File.size(file_path))
end

RSpec.describe 'Attachments API', :type => :request do
  
  before(:each) do
    @result = Result.create(FactoryGirl.attributes_for(:result))
    @upload_attr_hash_png = FactoryGirl.attributes_for(:upload_png)
    @upload_attr_hash_jpg = FactoryGirl.attributes_for(:upload_jpg)
    @upload_attr_hash_bmp = FactoryGirl.attributes_for(:upload_bmp)
    @upload_attr_hash_gif = FactoryGirl.attributes_for(:upload_gif)     
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
    @upload = Upload.create(@upload_attr_hash_png)
    params = {
      "api_key" => @user.single_access_token,
      'id' => @upload.id
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/search.json", params, request_headers
    expect(response.status).to eq(200)     
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['attachments'].count).to eq(1)
    verify_attachment(@upload, JSON.parse(response.body)['attachments'][0], @upload.upload.path)
    expect(JSON.parse(response.body)['attachments'][0]['data']).to eq(nil)
  end
  
  it "search by description found" do
    @upload = Upload.create(@upload_attr_hash_png)
    params = {
      "api_key" => @user.single_access_token,
      'description' => @upload.description
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/search.json", params, request_headers
    expect(response.status).to eq(200)     
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['attachments'].count).to eq(1)
    verify_attachment(@upload, JSON.parse(response.body)['attachments'][0], @upload.upload.path)
    expect(JSON.parse(response.body)['attachments'][0]['data']).to eq(nil)
  end
  
  it "search by file_name found" do
    @upload = Upload.create(@upload_attr_hash_png)
    params = {
      "api_key" => @user.single_access_token,
      'file_name' => @upload.upload_file_name
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/search.json", params, request_headers
    expect(response.status).to eq(200)     
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['attachments'].count).to eq(1)
    verify_attachment(@upload, JSON.parse(response.body)['attachments'][0], @upload.upload.path)
    expect(JSON.parse(response.body)['attachments'][0]['data']).to eq(nil)
  end   
    
   it "search by content_type found" do
    @upload = Upload.create(@upload_attr_hash_png)
    params = {
      "api_key" => @user.single_access_token,
      'content_type' => @upload.upload_content_type
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/search.json", params, request_headers
    expect(response.status).to eq(200)     
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['attachments'].count).to eq(1)
    verify_attachment(@upload, JSON.parse(response.body)['attachments'][0], @upload.upload.path)
    expect(JSON.parse(response.body)['attachments'][0]['data']).to eq(nil)
  end 
 
  it "search by parent_id found" do
    @upload = Upload.create(@upload_attr_hash_png)
    params = {
      "api_key" => @user.single_access_token,
      'parent_id' => @upload.uploadable_id
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/search.json", params, request_headers
    expect(response.status).to eq(200)     
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['attachments'].count).to eq(1)
    verify_attachment(@upload, JSON.parse(response.body)['attachments'][0], @upload.upload.path)
    expect(JSON.parse(response.body)['attachments'][0]['data']).to eq(nil)
  end 
 
  it "search by parent_type found" do
    @upload = Upload.create(@upload_attr_hash_png)
    params = {
      "api_key" => @user.single_access_token,
      'parent_type' => @upload.uploadable_type
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/search.json", params, request_headers
    expect(response.status).to eq(200)     
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['attachments'].count).to eq(1)
    verify_attachment(@upload, JSON.parse(response.body)['attachments'][0], @upload.upload.path)
    expect(JSON.parse(response.body)['attachments'][0]['data']).to eq(nil)
  end
 
   it "search multiple by parent_id found" do
    @upload_png = Upload.create(@upload_attr_hash_png)
    @upload_jpg = Upload.create(@upload_attr_hash_jpg)
    @upload_bmp = Upload.create(@upload_attr_hash_bmp)
    @upload_gif = Upload.create(@upload_attr_hash_gif)
    params = {
      "api_key" => @user.single_access_token,
      'parent_id' => @upload_png.uploadable_id
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/search.json", params, request_headers
    expect(response.status).to eq(200)     
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['attachments'].count).to eq(4)
    verify_attachment(@upload_png, JSON.parse(response.body)['attachments'][0], @upload_png.upload.path)
    expect(JSON.parse(response.body)['attachments'][0]['data']).to eq(nil)
    verify_attachment(@upload_jpg, JSON.parse(response.body)['attachments'][1], @upload_jpg.upload.path)
    expect(JSON.parse(response.body)['attachments'][1]['data']).to eq(nil)
    verify_attachment(@upload_bmp, JSON.parse(response.body)['attachments'][2], @upload_bmp.upload.path)
    expect(JSON.parse(response.body)['attachments'][2]['data']).to eq(nil)
    verify_attachment(@upload_gif, JSON.parse(response.body)['attachments'][3], @upload_gif.upload.path)
    expect(JSON.parse(response.body)['attachments'][3]['data']).to eq(nil)         
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
    @upload = Upload.create(@upload_attr_hash_png)
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
    verify_attachment(@upload, JSON.parse(response.body)['attachments'][0], @upload.upload.path)
    expect(JSON.parse(response.body)['attachments'][0]['data']).to eq(Base64.encode64(File.read(@upload.upload.path)))
  end
 
  it "download multiple by parent_id successful" do
    @upload_png = Upload.create(@upload_attr_hash_png)
    @upload_jpg = Upload.create(@upload_attr_hash_jpg)
    @upload_bmp = Upload.create(@upload_attr_hash_bmp)
    @upload_gif = Upload.create(@upload_attr_hash_gif)
    params = {
      "api_key" => @user.single_access_token,
      'parent_id' => @upload_png.uploadable_id
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/download.json", params, request_headers
    expect(response.status).to eq(200)     
    expect(JSON.parse(response.body)['found']).to eq(true)
    expect(JSON.parse(response.body)['attachments'].count).to eq(4)
    verify_attachment(@upload_png, JSON.parse(response.body)['attachments'][0], @upload_png.upload.path)
    expect(JSON.parse(response.body)['attachments'][0]['data']).to eq(Base64.encode64(File.read(@upload_png.upload.path)))
    verify_attachment(@upload_jpg, JSON.parse(response.body)['attachments'][1], @upload_jpg.upload.path)
    expect(JSON.parse(response.body)['attachments'][1]['data']).to eq(Base64.encode64(File.read(@upload_jpg.upload.path)))
    verify_attachment(@upload_bmp, JSON.parse(response.body)['attachments'][2], @upload_bmp.upload.path)
    expect(JSON.parse(response.body)['attachments'][2]['data']).to eq(Base64.encode64(File.read(@upload_bmp.upload.path)))
    verify_attachment(@upload_gif, JSON.parse(response.body)['attachments'][3], @upload_gif.upload.path)
    expect(JSON.parse(response.body)['attachments'][3]['data']).to eq(Base64.encode64(File.read(@upload_gif.upload.path)))  
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
 
  it "upload bmp successful" do
    description = 'test description'
    file_name = 'test.bmp'
    content_type = 'image/bmp'
    parent_id = 1
    parent_type = 'Result'
    params = {
      'api_key' => @user.single_access_token,
      'description' => description,
      'file_name' => file_name,
      'parent_id' => parent_id,
      'parent_type' => parent_type,
      'data' => Base64.encode64(File.read(Rails.root.join('spec/test_files/attachments/images/snake.bmp')))
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
    expect(JSON.parse(response.body)['size']).to eq(File.size(Rails.root.join('spec/test_files/attachments/images/snake.bmp')))
    expect(JSON.parse(response.body)['parent_id']).to eq(parent_id)
    expect(JSON.parse(response.body)['parent_type']).to eq(parent_type)
  end 

  it "upload gif successful" do
    description = 'test description'
    file_name = 'test.gif'
    content_type = 'image/gif'
    parent_id = 1
    parent_type = 'Result'
    params = {
      'api_key' => @user.single_access_token,
      'description' => description,
      'file_name' => file_name,
      'parent_id' => parent_id,
      'parent_type' => parent_type,
      'data' => Base64.encode64(File.read(Rails.root.join('spec/test_files/attachments/images/xynthia_animated.gif')))
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
    expect(JSON.parse(response.body)['size']).to eq(File.size(Rails.root.join('spec/test_files/attachments/images/xynthia_animated.gif')))
    expect(JSON.parse(response.body)['parent_id']).to eq(parent_id)
    expect(JSON.parse(response.body)['parent_type']).to eq(parent_type)
  end 

  it "upload multiple successful" do
    description = 'test description'
    file_name = 'test.png'
    parent_id = 1
    parent_type = 'Result'
    params = {
      'api_key' => @user.single_access_token,
      'attachments' => [
        { 'description' => 'test description',
          'file_name' => 'test.png',
          'content_type' => 'image/png',
          'parent_id' => 1,
          'parent_type' => 'Result',
          'data' => Base64.encode64(File.read(Rails.root.join('spec/test_files/attachments/images/snake.png')))},
        { 'description' => 'test description',
          'file_name' => 'test.jpg',
          'content_type' => 'image/jpg',
          'parent_id' => 1,
          'parent_type' => 'Result',
          'data' => Base64.encode64(File.read(Rails.root.join('spec/test_files/attachments/images/snake.jpg')))}                           
      ]
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/upload.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['attachments'].count).to eq(2)
    expect(JSON.parse(response.body)['attachments'][0]['file_name']).to eq('test.png')
    expect(JSON.parse(response.body)['attachments'][0]['content_type']).to eq('image/png')
    expect(JSON.parse(response.body)['attachments'][0]['size']).to eq(File.size(Rails.root.join('spec/test_files/attachments/images/snake.png')))
    expect(JSON.parse(response.body)['attachments'][1]['file_name']).to eq('test.jpg')
    expect(JSON.parse(response.body)['attachments'][1]['content_type']).to eq('image/jpeg')
    expect(JSON.parse(response.body)['attachments'][1]['size']).to eq(File.size(Rails.root.join('spec/test_files/attachments/images/snake.jpg')))
  end
 
   it "upload multiple invalid" do
    description = 'test description'
    file_name = 'test.png'
    parent_id = 1
    parent_type = 'Result'
    params = {
      'api_key' => @user.single_access_token,
      'attachments' => [
        { 'description' => 'test description',
          'file_name' => 'test.png',
          'content_type' => 'image/png',
          'parent_id' => 1,
          'parent_type' => 'Result',
          'data' => Base64.encode64(File.read(Rails.root.join('spec/test_files/attachments/images/snake.png')))},
        { 'description' => 'test description'},
        { }                           
      ]
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/upload.json", params, request_headers
    expect(response.status).to eq(400)
  end
 
  it "upload for non-Result object failure" do
    params = {
      'api_key' => @user.single_access_token,
      'description' => 'test description',
      'file_name' => 'test.png',
      'parent_id' => 1,
      'parent_type' => 'Device',
      'data' => 0
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/upload.json", params, request_headers
    expect(response.status).to eq(400)
  end
 
  it "upload for non-existent Result object failure" do
    params = {
      'api_key' => @user.single_access_token,
      'description' => 'test description',
      'file_name' => 'test.png',
      'parent_id' => 2,
      'parent_type' => 'Result',
      'data' => 0
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/upload.json", params, request_headers
    expect(response.status).to eq(400)
  end
 
  it "update attachment not found" do
    params = {
      "api_key" => @user.single_access_token,
      'to_update' => {
        'id' => 1,            
      },
      'new_values' => {  
        'description' => 'test description',
        'content_type' => 'image/png',
        'parent_id' => 1, 
        'parent_type' => 'Result',      
      }
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/update.json", params, request_headers
    expect(response.status).to eq(400) 
  end

  it "update Result not found" do
    @upload_png = Upload.create(@upload_attr_hash_png)
    params = {
      "api_key" => @user.single_access_token,
      'to_update' => {
        'id' => 1,            
      },
      'new_values' => {  
        'description' => 'test description',
        'content_type' => 'image/png',
        'parent_id' => 2, 
        'parent_type' => 'Result',      
      }
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/update.json", params, request_headers
    expect(response.status).to eq(400) 
  end

  it "update successful" do
    @upload_png = Upload.create(@upload_attr_hash_png)
    @result_2 = Result.create(FactoryGirl.attributes_for(:result_2))
    new_description = 'test description 2'
    new_content_type = 'image/jpeg'
    params = {
      "api_key" => @user.single_access_token,
      'to_update' => {
        'id' => @upload_png.id,            
      },
      'new_values' => {  
        'description' => new_description,
        'content_type' => new_content_type,
        'parent_id' => @result_2.id, 
        'parent_type' => 'Result',
      }
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/update.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['description']).to eq(new_description)
    expect(JSON.parse(response.body)['content_type']).to eq(new_content_type)
    expect(JSON.parse(response.body)['parent_id']).to eq(@result_2.id)
    expect(JSON.parse(response.body)['parent_type']).to eq('Result')    
  end


  it "update multiple successful" do
    @upload_png = Upload.create(@upload_attr_hash_png)
    @upload_jpg = Upload.create(@upload_attr_hash_jpg)
    @result_2 = Result.create(FactoryGirl.attributes_for(:result_2))
    new_description = 'test description 3'
    new_content_type = 'image/test'
    params = {
      "api_key" => @user.single_access_token,
      'attachments' => [
        {
          'to_update' => {
            'id' => @upload_png.id,            
          },
          'new_values' => {  
            'description' => new_description,
            'content_type' => new_content_type,
            'parent_id' => @result_2.id, 
            'parent_type' => 'Result',
          }
        },
        {
          'to_update' => {
            'id' => @upload_jpg.id,            
          },
          'new_values' => {  
            'description' => new_description,
            'content_type' => new_content_type,
            'parent_id' => @result_2.id, 
            'parent_type' => 'Result',
          }
         }        
      ]
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    post "api/attachments/update.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['attachments'].count).to eq(2)
    expect(JSON.parse(response.body)['attachments'][0]['description']).to eq(new_description)
    expect(JSON.parse(response.body)['attachments'][0]['content_type']).to eq(new_content_type)
    expect(JSON.parse(response.body)['attachments'][0]['parent_id']).to eq(@result_2.id)
    expect(JSON.parse(response.body)['attachments'][0]['parent_type']).to eq('Result')
    expect(JSON.parse(response.body)['attachments'][1]['description']).to eq(new_description)
    expect(JSON.parse(response.body)['attachments'][1]['content_type']).to eq(new_content_type)
    expect(JSON.parse(response.body)['attachments'][1]['parent_id']).to eq(@result_2.id)
    expect(JSON.parse(response.body)['attachments'][1]['parent_type']).to eq('Result')           
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
  end
 
  it "delete successful" do
    @upload_png = Upload.create(@upload_attr_hash_png)
    params = {
      "api_key" => @user.single_access_token,
      'id' => @upload_png.id
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    expect(File.exist?(@upload_png.upload.path)).to eq(true)
    post "api/attachments/delete.json", params, request_headers
    expect(response.status).to eq(200)
    post "api/attachments/search.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['found']).to eq(false)
    expect(File.exist?(@upload_png.upload.path)).to eq(false)
  end
 
  it "delete multiple successful" do
    @upload_png = Upload.create(@upload_attr_hash_png)
    @upload_jpg = Upload.create(@upload_attr_hash_jpg)
    params = {
      "api_key" => @user.single_access_token,
      'attachments' => [
        {'id' => @upload_png.id},
        {'id' => @upload_jpg.id},
      ]
    }.to_json
    request_headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
    expect(File.exist?(@upload_png.upload.path)).to eq(true)
    expect(File.exist?(@upload_jpg.upload.path)).to eq(true)
    post "api/attachments/delete.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['attachments'].count).to eq(2)
    params = {
      "api_key" => @user.single_access_token,
      'id' => @upload_png.id
    }.to_json    
    post "api/attachments/search.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['found']).to eq(false)
    expect(File.exist?(@upload_png.upload.path)).to eq(false)
    params = {
      "api_key" => @user.single_access_token,
      'id' => @upload_jpg.id
    }.to_json      
    post "api/attachments/search.json", params, request_headers
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['found']).to eq(false)
    expect(File.exist?(@upload_jpg.upload.path)).to eq(false)    
  end
 
  after(:each) do
    # remove test uploads directory
    FileUtils.rm_rf(Dir["#{Rails.root}/spec/test_files/test"])
  end

end