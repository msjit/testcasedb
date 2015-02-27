require 'json'
require 'base64'
require 'fileutils'

class Webapiv2Controller < ApplicationController
  skip_before_filter :require_login

  def validate_request(request)
    request_ok = false
    request_data = nil
    if request.format.symbol  =~ /json/
      begin
        request_data = JSON.parse(request.body.read)
        request_ok = true
      rescue
        message = 'Unable to parse JSON request data.'
        status = 400 
      end
    elsif request.format.symbol  =~ /xml/
      begin
        request_data = Hash.from_xml(request.body.read)
        request_ok = true
      rescue
        message = 'Unable to parse XML request data.'
        status = 400         
      end      
    else
      message = 'Request format symbol was blank or invalid. Must be ".json" or ".xml".'
      status = 400   
    end
    if !request_ok
      respond_to do |format|
        format.json {
          render :json => {'message' => message},
                 :status => status
        }
        format.xml {
          render :xml => {'message' => message}.to_xml(:root => 'response', :skip_types => true),
                 :status => status
        }
        format.all {
          render :text => message,
                 :status => status
        }        
      end
    end
    return request_ok, request_data
  end
  
  def authenticate_api_user(request_data)
    authenticated = false
    message = nil
    status = nil   
    if request_data && request_data.key?('api_key')
      api_key = request_data['api_key']     
      user = User.where(:single_access_token => api_key,
                        :role => 11)
      if user != []
        UserSession.create(user.first) 
        authenticated = true
      else
        message = "Invalid api_key."
        status = 401
      end
    else
      message = 'No api_key provided.'
      status = 400          
    end
    if !authenticated
      respond_to do |format|
        format.json {
          render :json => {'message' => message},
                 :status => status
        }
        format.xml {
          render :xml => {'message' => message}.to_xml(:root => 'response', :skip_types => true),
                 :status => status
        }                   
      end     
    end    
    return authenticated
  end
  
  def run
    response_hash = nil
    request_ok, request_data = validate_request(request)    
    return if !request_ok || !authenticate_api_user(request_data)    
    case params[:object]
    when 'products'
      response_hash = _products(params[:endpoint], request_data)
    when 'users'
      response_hash = _users(params[:endpoint], request_data)
    when 'versions'
      response_hash = _versions(params[:endpoint], request_data)
    when 'devices'
      response_hash = _devices(params[:endpoint], request_data)
    when 'categories'
      response_hash = _categories(params[:endpoint], request_data)
    when 'tags'
      response_hash = _tags(params[:endpoint], request_data)
    when 'test_cases'
      response_hash = _test_cases(params[:endpoint], request_data)
    when 'test_plans'
      response_hash = _test_plans(params[:endpoint], request_data)     
    when 'stencils'
      response_hash = _stencils(params[:endpoint], request_data)       
    when 'assignments'
      response_hash = _assignments(params[:endpoint], request_data)
    when 'results'
      response_hash = _results(params[:endpoint], request_data)                                                                                                  
    when 'attachments'
      response_hash = _attachments(params[:endpoint], request_data)                                                                                                  
    end
    if response_hash.nil?
      response_hash = {'response' => {'message' => 'Invalid API endpoint.'}, 'status' => 400}
    end
    respond_to do |format|
      format.json {
        render :json => response_hash['response'],
               :status => response_hash['status']
      }
      format.xml {
        render :xml => response_hash['response'].to_xml(:root => 'response', :skip_types => true),
               :status => response_hash['status']
      }
      format.all {
        render :text => 'Web API requests must be JSON or XML requests',
               :status => 400
      }                          
    end          
  rescue
    respond_to do |format|
      format.json {
        render :json => {'message' => 'Exception'},
               :status => 500
      }
      format.xml {
        render :xml => {'message' => 'Exception'}.to_xml(:root => 'response', :skip_types => true),
               :status => 500
      }          
    end      
  end

  def invalid    
    respond_to do |format|
      format.json {
        render :json => {'message' => 'Invalid API endpoint.'},
               :status => 400
      }
      format.xml {
        render :xml => {'message' => 'Invalid API endpoint.'}.to_xml(:root => 'response', :skip_types => true),
               :status => 400
      }      
      format.all {
        render :text => 'Web API requests must be JSON or XML requests',
               :status => 400
      }                    
    end    
  end

  private
  
  def _products(endpoint, request_data)
    case endpoint
    when "search"
      return _products_search(request_data)
    when 'create'
      return _products_create(request_data)      
    end
    return nil      
  end

  def _users(endpoint, request_data)
    case endpoint
    when "search"
      return _users_search(request_data)
    when "roles"
      return _users_roles(request_data)      
    end
    return nil      
  end
  
  def _versions(endpoint, request_data)
    case endpoint
    when 'search'
      return _versions_search(request_data)
    when 'create'
      return _versions_create(request_data)
    end
    return nil
  end  

  def _devices(endpoint, request_data)
    case endpoint
    when 'search'
      return _devices_search(request_data)
    when 'create'
      return _devices_create(request_data)
    end
    return nil  
  end

  def _categories(endpoint, request_data)
    case endpoint
    when 'search'
      return _categories_search(request_data)
    when 'create'
      return _categories_create(request_data)
    end
    return nil   
  end

  def _tags(endpoint, request_data)
    case endpoint
    when 'search'
      return _tags_search(request_data)
    when 'create'
      return _tags_create(request_data)
    end
    return nil   
  end

  def _test_cases(endpoint, request_data)
    case endpoint
    when 'search'
      return _test_cases_search(request_data)
    when 'create'
      return _test_cases_handler(request_data, 'create')
    when 'update'
      return _test_cases_handler(request_data, 'update')
    when "statuses"
      return _item_statuses()
    when "types"
      return _test_types()            
    end    
    return nil   
  end

  def _test_plans(endpoint, request_data)
    case endpoint
    when 'search'
      return _test_plans_search(request_data)
    when 'create'
      return _test_plans_create(request_data)
    when 'update'
      return _test_plans_update(request_data)
    when "statuses"
      return _item_statuses()               
    end
    return nil   
  end

  def _stencils(endpoint, request_data)
    case endpoint
    when 'search'
      return _stencils_search(request_data)
    when 'create'
      return _stencils_create(request_data)
    when 'update'
      return _stencils_update(request_data)
    when "statuses"
      return _item_statuses()            
    end
    return nil   
  end

  def _assignments(endpoint, request_data)
    case endpoint
    when 'search'
      return _assignments_search(request_data)
    when 'create'
      return _assignments_create(request_data)
    end
    return nil   
  end
  
  def _results(endpoint, request_data)
    case endpoint
    when 'get'
      return _results_get(request_data)
    when 'set'
      return _results_set(request_data)
    end
    return nil   
  end

  def _attachments(endpoint, request_data)
    case endpoint      
    when 'upload'
      return _attachments_handler(request_data, 'upload')
    when 'download'
      return _attachments_search(request_data, download=true)      
    when 'search'
      return _attachments_search(request_data)
    when 'update'
      return _attachments_handler(request_data, 'update')
    when 'delete'
      return _attachments_handler(request_data, 'delete')
    end
    return nil   
  end
  
  # handle creation and update of the custom fields
  # returns true or false and a message
  def _handle_custom_fields(request_data, item_type, item)  
    if item_type != "test_case" \
       && item_type != "test_plan" \
       && item_type != "assignment" \
       && item_type != "result" \
       && item_type != "device"
      return false, "_handle_custom_fields: invalid item_type parameter '#{item_type}'"
    end
    success = false
    message = ""
    # verify format of custom fields list
    if request_data['custom_fields'].is_a?(Array) \
       && !request_data['custom_fields'].empty?
      incorrect_fields = request_data['custom_fields'].map {|f| (f.is_a?(Hash) && !f.empty?) ? nil : f.to_s}.compact
      if incorrect_fields.count > 0
        return false, "One or more passed custom_fields were not of the correct type or empty"
      end
      # symbolize keys
      request_data['custom_fields'].map!{ |f| f.symbolize_keys!}                         
      # create custom field(s) if necessary      
      request_data['custom_fields'].each do |field|
        if field.key?(:name) && field.key?(:type)
          type = field[:type]
          if type == "string" \
             || type == "drop_down" \
             || type == "check_box" \
             || type == "radio_button" \
             || type == "number" \
             || type == "link"
            custom_fields = CustomField.where(:item_type => item_type,
                                              :field_name => field[:name],
                                              :field_type => type,
                                              :active => true)              
            if custom_fields == []
               
               custom_field = CustomField.new(:item_type => item_type,
                                              :field_name => field[:name],
                                              :field_type => type)            
               custom_field = custom_field.save
               # Only create results if object creation is successful
               if !custom_field                
                 return false, "_set_custom_fields: error creating new custom field '#{field[:name]}' for '#{item_type}' with type '#{type}'"
               end
             end
          else
            return false, "_set_custom_fields: invalid field_type parameter '#{type}'"
          end         
        else
          return false, "Custom field '" + field.to_s + "' does not contain both a name and type child element."        
        end
      end
      custom_fields = CustomField.where(:item_type => item_type,
                                        :active => true)    
      # set custom field for item
      if custom_fields.count > 0
        request_data['custom_fields'].each do |field|
          # verify that the custom field has a name and value
          if field.key?(:name) && field.key?(:value)
            # if the custom field passed with the request exists then add it to the result
            custom_field = custom_fields.map {|x| x.field_name == field[:name] ? x : nil}.compact
            if custom_field.count > 0
              # If a custom item entry for the current field doesn't exist, add it,
              # otherwise just set it
              custom_item = item.custom_items.where(:custom_field_id => custom_field.first.id).first
              if custom_item == nil
                item.custom_items.build(:custom_field_id => custom_field.first.id,
                                        :value => field[:value])
              else
                custom_item.value = field[:value]
                custom_item.save
              end
              success = true
            else
              message = 'Custom field ' + field[:name] + ' does not exist'
              success = false
            end   
          else
            message = "Custom field " + field.to_s + " does not contain a name and value child element."         
            success = false
          end
        end     
      end
    else
      message = "Passed custom field list was empty or invalid."
    end
    return success, message
  end  
  
  def _handle_test_case_tags(request_data, test_case)  
    if request_data['tags'].is_a?(Array) \
       && !request_data['tags'].empty?
      incorrect_tags = request_data['tags'].map {|x| (x.is_a?(String) || x.is_a?(Integer))  ? nil : x.to_s}.compact
      if incorrect_tags.count > 0 
        message = 'One or more passed tags were neither of type String or Integer'         
        return false, message        
      end               
      request_data['tags'].each do |tag|
        if tag.is_a?(String)
          response_hash = _tags_create({'name' => tag})
          if response_hash['status'] != 201 \
             && !(response_hash['status'] == 200 && response_hash['response']['found'])
            message = 'There was a problem finding or creating tag "%s" for test case "%s"' \
                      %[tag, test_case.name]            
            return false, message
          end
        else
          response_hash = _tags_search({'id' => tag})
          if !(response_hash['status'] == 200 && response_hash['response']['found'])
            message = 'Tag "%s" for test case "%s" was not found and no name was provided ' \
                      'to allow automatic creation.' %[tag, test_case.name]                   
            return false, message                
          end    
        end
        if response_hash['status'] == 201
          tag_id = response_hash['response']['id']
        else
          tag_id = response_hash['response']['tags'][0][:id]
        end
        tag_test_case = test_case.tag_test_cases.where(:tag_id => tag_id,
                                                       :test_case_id => test_case.id).first
        if tag_test_case == nil      
          tag_test_case = TagTestCase.new(:tag_id => tag_id,
                                          :test_case_id => test_case.id)
          tag_test_case.save  
        end               
      end
      return true, '' 
    else          
      return false, 'tags was not an Array or is empty'                        
    end                
  end
  
  def _get_custom_fields(item_type, item)
    if item_type != "test_case" \
       && item_type != "test_plan" \
       && item_type != "assignment" \
       && item_type != "result" \
       && item_type != "device"
      return nil
    end   
    custom_fields = 
      item.custom_fields.map do |cf|
        { name: cf[:field_name],
          type: cf[:field_type],
          value: CustomItem.where("#{item_type}_id".to_sym => item.id, :custom_field_id => cf.id).first.value } 
      end
    return custom_fields
  rescue
    return nil   
  end
  
  def _get_test_case_tags(test_case)      
    tags = 
      test_case.tags.map do |t|
        { name: t[:name],
          id: t[:id] }
      end
    return tags
  rescue
    return nil  
  end   
  
  def _get_status(request_data)
    status = request_data['status']
    if status
      if status.is_a?(Integer) \
         && (I18n.t :item_status).key?(status)
         return status, ''
      elsif status.is_a?(String) \
            && (I18n.t :item_status).key(status)
         return (I18n.t :item_status).key(status), ''           
      end
      return nil, 'Invalid status "%s"' %[status]      
    end
    return 1, ''
  rescue
    return nil, 'Invalid status "%s"' %[status]  
  end
  
  def _item_statuses()
    return {'response' => {'message' => 'Retrieved statuses.',
                           'statuses' => (I18n.t :item_status)},
            'status' => 200}
  end  
  
  def _test_types(name=nil, id=nil)      
    conditions = {:name => name,
                  :id => id }            
    conditions.delete_if {|k,v| v.blank? }     
    test_types = TestType.find(:all, :conditions => conditions)    
    test_types = test_types.map do |tt|
      { id: tt[:id],
        name: tt[:name],
        description: tt[:description] }
    end  
    response_hash = {'test_types' => test_types}    
    if test_types.count > 0
      response_hash['message'] = 'Test type(s) found.'
      response_hash['found'] = true
    else
      response_hash['message'] = 'No test type(s) found.'
      response_hash['found'] = false      
    end     
    return {'response' => response_hash,
            'status' => 200}
  end
  
  def _get_category_hierarchy(category)
    category_hierarchy = [{'name' => category.name,
                           'id' => category.id,
                           'product_id' => category.product_id,
                           'parent_id' => category.category_id}]
    category_hierarchy_string = category.name    
    product_id = category.product_id  
    loop do
      break if category.category_id.nil?
      category = Category.where(:product_id => product_id,
                                :id => category.category_id).first 
                                   
      category_hierarchy.unshift({'name' => category.name,
                                  'id' => category.id,
                                  'product_id' => category.product_id,
                                  'parent_id' => category.category_id})                                        
      category_hierarchy_string = "%s/%s" %[category.name, category_hierarchy_string]
    end   
    return category_hierarchy, category_hierarchy_string 
  end  
  
  def get_test_plan_cases(test_plan)   
    plan_cases = test_plan.plan_cases.map do |tp|
      { plan_case_id: tp[:id],
        test_case_id: tp[:test_case_id],
        case_order: tp[:case_order] }
    end
    return plan_cases 
  end
  
  def _products_search(request_data)
    response_hash = {}  
    if request_data['name'] == nil \
       && request_data['id'] == nil 
      response_hash["message"] = "No search parameters provided. Please specify one or more of the following: " \
                                 "%s." %[request_data['indirect_call'] ? "'product_name', 'product_id'" : "'name', 'id'"]
      return {'response' => response_hash,
              'status' => 400}   
    end
    conditions = {:name => request_data['name'],
                  :id => request_data['id'] }
    conditions.delete_if {|k,v| v.blank? }    
    products = Product.find(:all, :conditions => conditions)
    if products != []
      response_hash["products"] = 
        products.map do |p|
          { name: p[:name],
            id: p[:id],
            description: p[:description] }
        end                                                       
      response_hash["message"] = "Product(s) found."
      response_hash["found"] = true
    else
      response_hash["message"] = "No product(s) found. Try searching based on another parameter."
      response_hash["found"] = false
    end
    return {'response' => response_hash,
            'product' => products.first,
            'status' => 200}    
  end   
  
  def _products_create(request_data)
    response_hash = _products_search(request_data)   
    if response_hash["status"] == 200 && !response_hash['response']['found'] 
      product = Product.new(:name => request_data['name'],
                            :description => request_data['description'] )
      if product.save
        response_hash = {
          'response' => {
            'message' => 'Product created successfully.',
            'name' => product.name,
            'id' => product.id,
            'description' => product.description
          },
          'status' => 201
        }        
      else
        response_hash = {
          'response' => {'message' => 'Error creating product.'},
          'status' => 500
        }         
      end
    end   
    return response_hash
  end   
  
  def _users_search(request_data)
    response_hash = {}  
    if request_data['id'] == nil \
       && request_data['username'] == nil \
       && request_data['email'] == nil \
       && request_data['first_name'] == nil \
       && request_data['last_name'] == nil
      response_hash["message"] = "No search parameters provided. Please specify one or more of the following: " \
                                 "'id', 'username', 'email', 'first_name', 'last_name'."
      return {'response' => response_hash,
              'status' => 400}   
    end
    conditions = {:id => request_data['id'],
                  :username => request_data['username'],
                  :email => request_data['email'],
                  :first_name => request_data['first_name'],
                  :last_name => request_data['last_name'] }
    conditions.delete_if {|k,v| v.blank? }    
    users = User.find(:all, :conditions => conditions)
    if users != []
      response_hash["users"] = 
        users.map do |u|
          { username: u[:username],
            email: u[:email],
            first_name: u[:first_name],
            last_name: u[:last_name],
            id: u[:id],
            role: (I18n.t :user_roles)[u[:role]] }
        end                                                       
      response_hash["message"] = "User(s) found."
      response_hash["found"] = true
    else
      response_hash["message"] = "No user(s) found. Try searching based on another parameter."
      response_hash["found"] = false
    end
    return {'response' => response_hash,
            'status' => 200}    
  end  
  
  def _users_roles(request_data)
    return {'response' => {'message' => (I18n.t :user_roles)},
            'status' => 200}
  end
  
  def _versions_search(request_data)
    response_hash = {}
    if request_data['product_name'] || request_data['product_id']
      response_hash = _products_search({'name' => request_data['product_name'],
                                        'id' => request_data['product_id'],
                                        'indirect_call' => true})
      if !(response_hash["status"] == 200 && response_hash['response']['found'])
        return response_hash
      end
      product = response_hash['product']
    elsif request_data['version'].nil? && request_data['id'].nil?
      response_hash["message"] = "No search parameters provided. Please specify one or more of the following: " \
                                 "%s." %[request_data['indirect_call'] ? "'product_version', 'product_version_id'" : "'version', 'id'"]
      return {'response' => response_hash,
              'status' => 400}                
    end      
    conditions = {:id => request_data['id'],
                  :version => request_data['version'],
                  :product_id => product ? product.id : nil}
    conditions.delete_if {|k,v| v.blank?}    
    versions = Version.find(:all, :conditions => conditions, :order => "id ASC") 
    if versions != []
      versions_map = 
        versions.map do |v|
          { 'id' => v[:id],
            'version' => v[:version],
            'description' => v[:description],
            'product_id' => v[:product_id] }
        end         
      response_hash = {
        'response' => {'versions' => versions_map,
                       'message' => 'Version(s) found.',
                       'found' => true},
        'status' => 200,
      }
    else
      response_hash = {
        'response' => {'version' => nil,
                       'message' => "No Version(s) found. Try searching based on another parameter.",
                       'found' => false},
        'status' => 200,
        'product' => product    
      }
    end
    return response_hash
  end
  
  def _versions_create(request_data)
    if request_data['product_name'].nil? && request_data['product_id'].nil? 
      response_hash["message"] = "No product_name or product_id parameter provided"
      return {'response' => response_hash,
              'status' => 400}
    end    
    response_hash = _versions_search({'product_name' => request_data['product_name'],
                                      'product_id' => request_data['product_id'],
                                      'version' => request_data['version'],
                                      'version_id' => request_data['version_id'],
                                      'indirect_call' => true})  
    if response_hash["status"] == 200 && !response_hash['response']['found']
      version = Version.new(:version => request_data['version'],
                            :product_id => response_hash['product'].id,
                            :description => request_data['description'])
      if version.save
        response_hash = {
          'response' => {
            'message' => 'Version created successfully.',
            'id' => version.id,
            'version' => version.version,            
            'description' => version.description,
            'product_id' => version.product_id
          },
          'status' => 201
        }        
      else
        response_hash = {
          'response' => {'message' => 'Error creating version.'},
          'status' => 500
        }         
      end
    end   
    return response_hash
  end 
  
  def _devices_search(request_data)
    response_hash = {}  
    if request_data['name'] == nil \
       && request_data['id'] == nil
      response_hash["message"] = "No search parameters provided. Please specify one or more of the following: " \
                                 "'name', 'id' and optionally 'description' or 'custom_fields'."
      return {'response' => response_hash,
              'status' => 400}   
    end
    conditions = {:name => request_data['name'],
                  :id => request_data['id'],
                  :description => request_data['description']}
    conditions.delete_if {|k,v| v.blank? }    
    devices = Device.find(:all, :conditions => conditions)
    matching_devices = []
    if devices != []      
      if request_data['custom_fields']
        matching_devices = 
          devices.map do |d|
            { id: d[:id],
              name: d[:name],
              description: d[:description],
              custom_fields: _get_custom_fields('device', d),
              custom_fields_comparison: request_data['custom_fields']
            } if _get_custom_fields('device', d) == request_data['custom_fields'].map{ |f| f.symbolize_keys!}
          end
      else
        matching_devices =
          devices.map do |d|
            { id: d[:id],
              name: d[:name],
              description: d[:description],
              custom_fields: _get_custom_fields('device', d) }
          end
      end
    end
    matching_devices = matching_devices.compact
    if matching_devices != []
      response_hash["devices"] = matching_devices
      response_hash["message"] = "Device(s) found."
      response_hash["found"] = true
    else
      response_hash["message"] = "No device(s) found. Try searching based on another parameter."
      response_hash["found"] = false
    end
    return {'response' => response_hash,
            'status' => 200}
  end

  def _devices_create(request_data)                      
    response_hash = _devices_search(request_data)
    if response_hash["status"] == 200 && !response_hash['response']['found'] 
      device = Device.new(:name => request_data['name'],
                          :active => true,
                          :description =>  request_data['description'])
      if request_data.key?('custom_fields')
        success, message = _handle_custom_fields(request_data, "device", device)
        if !success
          response_hash = {
            'response' => {'message' => message},
            'status' => 400
          }           
          return response_hash   
        end
      end                                                     
      if device.save
        device_custom_fields = _get_custom_fields('device', device)
        response_hash = {
          'response' => {
            'message' => 'Device created successfully.',
            'id' => device.id,
            'name' => device.name,
            'description' => device.description,
            'custom_fields' => device_custom_fields
          },
          'status' => 201
        }        
      else
        response_hash = {
          'response' => {'message' => 'Error creating device.'},
          'status' => 500
        }         
      end
    end   
    return response_hash
  end  
  
  def _categories_search(request_data)
    response_hash = _products_search({'name' => request_data['product_name'],
                                      'id' => request_data['product_id']})
    if response_hash["status"] == 200 && response_hash['response']['found'] 
      product = response_hash['product']
      parent_category = nil
      current_category = nil
      all_categories = nil       
      if request_data['category'] != nil
        categories = request_data['category'].split(/[\\\/]/)
        all_categories = categories.clone            
      else
        response_hash = {
          'response' => {'message' => 'No category provided.'},
          'status' => 400
        }          
        return response_hash
      end
      parent_category = Category.where(:name => categories[0],
                                       :product_id => product.id,
                                       :category_id => nil).first                                         
      if parent_category == nil      
        response_hash = {
          'response' => {'message' => 'Parent category "%s" not found for product "%s".' %[categories[0], product.name],
                         'found' => false},
          'status' => 200,
          'product' => product,
          'current_category' => current_category,
          'categories' => all_categories          
        }
        return response_hash        
      end
      current_category = parent_category
      categories_so_far = [parent_category.name]
      categories.shift()
      categories.each do |category|
        categories_so_far.push(category)
        current_category = Category.where(:name => category,
                                          :category_id => parent_category.id).first
        if current_category == nil
          response_hash = {
            'response' => {'message' => 'Sub category "%s" not found for product "%s".' %[categories_so_far.join('/'), product.name],
                           'found' => false},
            'status' => 200,
            'product' => product,
            'current_category' => current_category,
            'categories' => all_categories            
          }          
          return response_hash         
        end
        parent_category = current_category
      end
      category_hierarchy, category_hierarchy_string = _get_category_hierarchy(current_category)
      response_hash = {
        'response' => {'message' => 'Found category hierarchy "%s" for product "%s"' %[categories_so_far.join('/'), product.name],
                       'product' => product.name,
                       'product_id' => product.id,
                       'id' => current_category.id,
                       'category' => category_hierarchy_string,                       
                       'category_hierarchy' => category_hierarchy,
                       'found' => true},
        'status' => 200,
        'product' => product,
        'current_category' => current_category,
        'categories' => all_categories        
      }
    else
      response_hash['response']['message'] = 'Categories Search: %s' %[response_hash['response']['message']]
      response_hash['status'] = 400
    end
    return response_hash     
  end
 
  def _categories_create(request_data)    
    response_hash = _categories_search(request_data)    
    if response_hash["status"] == 200 && !response_hash['response']['found'] && response_hash['product']
      categories = response_hash['categories']
      product = response_hash['product']     
      parent_category = Category.where(:name => categories[0],
                                       :product_id => product.id,
                                       :category_id => nil).first                                             
      if parent_category == nil
        parent_category = Category.new(:name => categories[0],
                                       :product_id => product.id)                                        
        if !parent_category.save
          response_hash = {
            'response' => {'message' => 'Error creating parent category "%s".' %[categories[0]]},
            'status' => 500
          }          
          return response_hash        
        end
      end
      categories_so_far = [parent_category.name]
      categories.shift()
      current_category = parent_category
      categories.each do |category|             
        categories_so_far.push(category)
        current_category = Category.where(:name => category,
                                          :category_id => parent_category.id,
                                          :product_id => product.id).first                                                               
        if current_category == nil
          current_category = Category.new(:name => category,
                                          :category_id => parent_category.id,
                                          :product_id => product.id)                                                                                                                
          if !current_category.save
            response_hash = {
              'response' => {'message' => 'Error creating sub category "%s" for product "%s".' %[categories_so_far.join('/'), product.name]},
              'status' => 500
            }            
            return response_hash          
          end          
        end
        parent_category = current_category                                      
      end      
      category_hierarchy, category_hierarchy_string = _get_category_hierarchy(current_category)
      response_hash = {
        'response' => {'message' => 'Successfully created category hierarchy',
                       'id' => current_category.id,
                       'category' => category_hierarchy_string,
                       'category_id' => current_category.id,
                       'category_hierarchy' => category_hierarchy,                       
                       'product'  => product.name},
        'status' => 201
      }           
    end   
    return response_hash
  end  
  
   def _tags_search(request_data)
    response_hash = {}  
    if request_data['name'] == nil \
       && request_data['id'] == nil 
      response_hash["message"] = "No search parameters provided. Please specify one or more of the following: " \
                                 "'name', 'id'."
      return {'response' => response_hash,
              'status' => 400}   
    end
    conditions = {:name => request_data['name'],
                  :id => request_data['id'] }
    conditions.delete_if {|k,v| v.blank? }    
    tags = Tag.find(:all, :conditions => conditions)
    if tags != []
      response_hash["tags"] = 
        tags.map do |t|
          { name: t[:name],
            id: t[:id] }
        end                                                       
      response_hash["message"] = "Tag(s) found."
      response_hash["found"] = true
    else
      response_hash["message"] = "No tag(s) found. Try searching based on another parameter."
      response_hash["found"] = false
    end
    return {'response' => response_hash,
            'status' => 200}    
  end   
  
  def _tags_create(request_data)
    response_hash = _tags_search(request_data)   
    if response_hash['status'] == 200 && !response_hash['response']['found']
      if !request_data['name']
        return {
          'response' => {'message' => 'No name provided to create tag from.'},
          'status' => 400
        }         
      end
      tag = Tag.new(:name => request_data['name'])
      if tag.save
        response_hash = {
          'response' => {
            'message' => 'Tag created successfully.',
            'name' => tag.name,
            'id' => tag.id
          },
          'status' => 201
        }        
      else
        response_hash = {
          'response' => {'message' => 'Error creating tag.'},
          'status' => 500
        }         
      end
    end   
    return response_hash
  end 
  
  def _test_cases_search(request_data)
    response_hash = _categories_search(request_data)
    test_case = nil
    if response_hash["status"] == 200 && response_hash['response']['found']
      category = response_hash['current_category']
      product = response_hash['product']
      categories = response_hash['categories']
      response_hash = {}        
      if request_data['name'] == nil \
         && request_data['id'] == nil 
        response_hash["message"] = "No search parameters provided. Please specify one or more of the following: " \
                                   "'name', 'id'."
        return {'response' => response_hash,
                'status' => 400}   
      end
      conditions = {:name => request_data['name'],
                    :id => request_data['id'] }             
      if categories.length > 1
        conditions[:category_id] = category.id
      else
        conditions[:product_id] = product.id
      end
      conditions.delete_if {|k,v| v.blank? }    
      test_case = TestCase.find(:all, :conditions => conditions) 
      if test_case == []
        response_hash = {
          'response' => {'message' => 'Test case "%s" not found for product "%s" in category hierarchy "%s".' \
                                      %[request_data['name'] || request_data['id'], product.name, categories.join('/')],
                         'found' => false},
          'status' => 200,
          'product' => product,
          'test_case' => test_case,
          'category' => category         
        }           
      else
        current_test_case = test_case.map {|x| x.deprecated == false ? x : nil}.compact
        if current_test_case.count > 0            
          test_case = current_test_case.first          
          test_case_custom_fields = _get_custom_fields('test_case', test_case)
          test_case_tags = _get_test_case_tags(test_case)
          category_hierarchy, category_hierarchy_string = _get_category_hierarchy(test_case.category)                         
          response_hash = {
            'response' => {'message' => 'Test case found.',
                           'id' => test_case.id,
                           'name' => test_case.name,
                           'description' => test_case.description,
                           'version' => test_case.version,
                           'parent_id' => test_case.parent_id ? test_case.parent_id : nil,
                           'product'=> product.name,
                           'product_id' => product.id,
                           'tags' => test_case_tags,
                           'custom_fields' => test_case_custom_fields,
                           'category' => category_hierarchy_string,
                           'category_id' => test_case.category.id,
                           'category_hierarchy' => category_hierarchy,
                           'status' => (I18n.t :item_status)[test_case.status],
                           'found' => true},            
            'status' => 200,
            'product' => product,
            'test_case' => test_case,
            'category' => category
          }             
        else
          response_hash = {
            'response' => {'message' => 'No current test case was found.  All matching test cases were deprecated.',
                           'found' => false},
            'status' => 200,
            'product' => product,
            'test_case' => test_case,
            'category' => category
          }            
        end          
      end
    else
      response_hash["status"] = 400
    end    
    return response_hash
  end

  def _test_cases_handler(request_data, action)
    if request_data.key?('test_cases')
      if request_data['test_cases'].is_a?(Hash) \
         && !request_data['test_cases'].empty?
        incorrect_fields = request_data['test_cases'].map {|k,v| (v.is_a?(Hash) && !v.empty?) ? nil : k.to_s}.compact
        if incorrect_fields.count > 0        
          return {'response' => {'message' => 'One or more passed test_cases were not of the correct type or empty.'},
                  'status' => 400}        
        end       
        response_hash = {'test_cases' => []}
        request_data['test_cases'].each do |key, value|
          if action == 'create'
            result = _test_cases_create(value)
            response_hash['message'] = 'Successfully created all test cases'
          elsif action == 'update'
            result = _test_cases_update(value)
            response_hash['message'] = 'Successfully updated all test cases'
          end
          if result["status"] == 200 || result["status"] == 201
            response_hash['test_cases'].push(result['response'])
          else
            return result
          end          
        end
        return {'response' => response_hash,
                'status' => 200}     
      else
        return {'response' => {'message' => 'Passed test_cases list was empty or invalid.'},
                'status' => 400}
      end
    else
      if action == 'create'
        return _test_cases_create(request_data)
      elsif action == 'update'
        return _test_cases_update(request_data)
      end
    end
  end

  def _test_cases_create(request_data)
    if !request_data['new_version']
      request_data.delete('id')
    end

    response_hash = _categories_search(request_data)
    if response_hash["status"] == 200 && !response_hash['response']['found'] 
      response_hash = _categories_create(request_data)
      if response_hash["status"] != 201
        return response_hash
      end
    elsif response_hash["status"] != 200
      return response_hash
    end
  
    response_hash = _test_cases_search(request_data)
    product = response_hash['product']
    test_case = response_hash['test_case']
    category = response_hash['category']    
    if response_hash["status"] == 200 \
       && product && category
      product = response_hash['product']
      test_case = response_hash['test_case']
      category = response_hash['category']
      categories = response_hash['category']     
      if response_hash['response']['found']
        if request_data['new_version']
          # Find the parent test case ID
          original_test_case = test_case         
          parent_id = view_context.find_test_case_parent_id(original_test_case)         
          # Find the current max version for this parent id
          max_version = TestCase.where( "id = ? OR parent_id = ?", parent_id, parent_id ).maximum(:version)   
          # clone the test case
          test_case = original_test_case.dup 
          # Remember to increate the version value
          test_case.version = max_version + 1
          test_case.parent_id = parent_id
          test_case.save        
          # Make a clone of each step for this test case
          original_test_case.steps.each do |step|
            new_step = step.dup
            new_step.test_case_id = test_case.id
            new_step.save
          end
          # Make a clone of each custom field for this test case
          original_test_case.custom_items.each do |item|
            new_item = item.dup
            new_item.test_case_id = test_case.id
            new_item.save
          end
          # Make a clone of each tag for this test case
          original_test_case.tag_test_cases.each do |tag|
            new_tag = tag.dup
            new_tag.test_case_id = test_case.id
            new_tag.save
          end               
          # Mark the earlier test case as deprecated
          original_test_case.deprecated = true
          original_test_case.save
          test_case_custom_fields = _get_custom_fields('test_case', test_case)
          test_case_tags = _get_test_case_tags(test_case)
          category_hierarchy, category_hierarchy_string = _get_category_hierarchy(test_case.category)                 
          response_hash = {
            'response' => {'message' => 'Successfully created new test case version for "%s" for product "%s" in category hierarchy "%s".' \
                                        %[test_case.name, product.name, category_hierarchy_string],
                           'id' => test_case.id,
                           'name' => test_case.name,
                           'description' => test_case.description,
                           'version' => test_case.version,
                           'parent_id' => test_case.parent_id ? test_case.parent_id : nil,
                           'product'=> product.name,
                           'product_id' => product.id,
                           'tags' => test_case_tags,
                           'custom_fields' => test_case_custom_fields,
                           'category' => category_hierarchy_string,
                           'category_id' => test_case.category.id,
                           'category_hierarchy' => category_hierarchy,
                           'status' => (I18n.t :item_status)[test_case.status],
                           'test_type_id' => test_case.test_type_id                        
                           },
            'status' => 201
          }              
        end
      else          
        if request_data['new_version']
          return {'response' => {'message' => 'Test case "%s" not found for product "%s" in category hierarchy "%s" to create new version from.' \
                                  %[request_data['name'] || request_data['id'], product.name, categories],
                                  'found' => false},
                  'status' => 400}                            
        end        
        if request_data['name'] == nil
          return {'response' => {'message' => 'No name provided.'},
                  'status' => 400}   
        end
        if request_data['test_type_id'] \
           || request_data['test_type_name']
          response_hash = _test_types(request_data['test_type_name'],
                                      request_data['test_type_id'])
          if response_hash["status"] == 200 && response_hash['response']['found']
            test_type_id = response_hash['response']['test_types'].first['id']
          else
            response_hash["status"] = 400
            return response_hash
          end                                      
        end
        created_by_id = request_data['created_by_id']
        if created_by_id
          response_hash = _users_search({'id' => created_by_id})
          if !response_hash['response']['found']
            response_hash["status"] = 400
            return response_hash
          end          
        end
        status, message = _get_status(request_data)
        if !status
          return {'response' => {'message' => message},
                  'status' => 400}          
        end
        test_case = TestCase.new(:name => request_data['name'],
                                 :description => request_data['description'],
                                 :category_id => category ? category.id : nil,
                                 :product_id => product.id,
                                 :status => status,
                                 :test_type_id => test_type_id ? test_type_id : 2,
                                 :created_by_id => created_by_id ? created_by_id : 1)                                       
        test_case.steps.build(:step_number => 1)
        test_case.test_case_targets.build
        # handle custom fields if any  
        if request_data.key?('custom_fields')
          success, message = _handle_custom_fields(request_data, "test_case", test_case)
          if !success
            response_hash = {
              'response' => {'message' => message},
              'status' => 400
            }           
            return response_hash   
          end
        end                  
        if test_case.save
          # handle tags
          if request_data.key?('tags')          
            success, message = _handle_test_case_tags(request_data, test_case)
            if !success
              response_hash = {
                'response' => {'message' => message},
                'status' => 400
              }           
              return response_hash   
            end
          end
          test_case_custom_fields = _get_custom_fields('test_case', test_case)
          test_case_tags = _get_test_case_tags(test_case)
          category_hierarchy, category_hierarchy_string = _get_category_hierarchy(test_case.category)                  
          response_hash = {
            'response' => {'message' => 'Successfully created test case "%s" for product "%s" in category hierarchy "%s".' \
                                        %[test_case.name, product.name, category_hierarchy_string],
                           'id' => test_case.id,
                           'name' => test_case.name,
                           'description' => test_case.description,
                           'version' => test_case.version,
                           'parent_id' => test_case.parent_id ? test_case.parent_id : nil,
                           'product'=> product.name,
                           'product_id' => product.id,
                           'category' => category_hierarchy_string,
                           'category_id' => test_case.category.id,
                           'category_hierarchy' => category_hierarchy,                          
                           'tags' => test_case_tags,
                           'custom_fields' => test_case_custom_fields,
                           'status' => (I18n.t :item_status)[test_case.status]                        
                           },
            'status' => 201
          }                    
        else
          category_hierarchy, category_hierarchy_string = _get_category_hierarchy(test_case.category)
          response_hash = {
            'response' => {'message' => 'Error creating test case "%s" in category "%s" for product "%s".' \
                                        %[test_case.name, category_hierarchy_string, product.name]},
            'status' => 500
          }           
        end             
      end
    end
    return response_hash
  end

  def _test_cases_update(request_data)
    if request_data['to_update'] == nil \
       && request_data['new_values'] == nil
      return {'response' => {'message' => "No to_update or new_values passed."},
              'status' => 400}   
    end     
    response_hash = _test_cases_search(request_data['to_update'])     
    if response_hash["status"] == 200 && response_hash['response']['found']
      product = response_hash['product']
      test_case = response_hash['test_case']
      category = response_hash['category']     
      test_case.name = request_data['new_values']['name'] || test_case.name
      test_case.description = request_data['new_values']['description'] || test_case.description       
      if request_data['new_values']["category"] || request_data["category_id"]           
        response_hash = _categories_search(request_data['new_values'])
        if response_hash["status"] == 200 && response_hash['response']['found']
          test_case.category =  response_hash['current_category']
          test_case.category_id = response_hash['response']['id']
          test_case.product = response_hash['product']
          test_case.product_id = response_hash['response']['product_id']          
        else
          return response_hash
        end
      end
      if request_data['new_values']['status']
        status, message = _get_status(request_data['new_values'])
        if !status
          return {'response' => {'message' => message},
                  'status' => 400}          
        end
        test_case.status = status
      end                        
      if request_data['new_values']['test_type_id'] \
         || request_data['new_values']['test_type_name']
        response_hash = _test_types(request_data['new_values']['test_type_name'],
                                    request_data['new_values']['test_type_id'])
        if response_hash["status"] == 200 && response_hash['response']['found']
          test_case.test_type_id = response_hash['response']['test_types'].first['id']
        else
          response_hash["status"] = 400
          return response_hash
        end                                    
      end
      created_by_id = request_data['new_values']['created_by_id']
      if created_by_id
        response_hash = _users_search({'id' => created_by_id})
        if response_hash["status"] == 200 && response_hash['response']['found']
           test_case.created_by_id = response_hash['response']['users'].first['id']
        else
          response_hash["status"] = 400
          return response_hash
        end          
      end                
      # handle custom fields if any
      if request_data['new_values']['overwrite_custom_fields']
        test_case.custom_fields.destroy_all
      end        
      if request_data['new_values'].key?('custom_fields')
        success, message = _handle_custom_fields(request_data['new_values'], "test_case", test_case)
        if !success
          response_hash = {
            'response' => {'message' => message},
            'status' => 400
          }           
          return response_hash   
        end
      end                  
      # handle tags
      if request_data['new_values']['overwrite_tags']
        test_case.tags.delete_all
      end      
      if request_data['new_values'].key?('tags')          
        success, message = _handle_test_case_tags(request_data['new_values'], test_case)
        if !success
          response_hash = {
            'response' => {'message' => message},
            'status' => 400
          }           
          return response_hash   
        end
      end         
      if test_case.save
        test_case.reload
        test_case_custom_fields = _get_custom_fields('test_case', test_case)
        test_case_tags = _get_test_case_tags(test_case) 
        category_hierarchy, category_hierarchy_string = _get_category_hierarchy(test_case.category)            
        response_hash = {
          'response' => {'message' => 'Successfully updated test case "%s" for product "%s" in category hierarchy "%s".' \
                                      %[test_case.name, product.name, category_hierarchy_string],
                         'id' => test_case.id,
                         'name' => test_case.name,
                         'description' => test_case.description,
                         'version' => test_case.version,
                         'parent_id' => test_case.parent_id ? test_case.parent_id : nil,
                         'product'=> product.name,
                         'product_id' => product.id,
                         'tags' => test_case_tags,
                         'custom_fields' => test_case_custom_fields,
                         'category' => category_hierarchy_string,
                         'category_id' => test_case.category.id,
                         'category_hierarchy' => category_hierarchy,
                         'status' => (I18n.t :item_status)[test_case.status]                        
                         },
          'status' => 200
        }                       
      else
        category_hierarchy, category_hierarchy_string = _get_category_hierarchy(test_case.category)
        response_hash = {
          'response' => {'message' => 'Error updating test case "%s" in category "%s" for product "%s".' \
                                      %[test_case.name, category_hierarchy_string, product.name]},
          'status' => 500
        }           
      end
    end
    return response_hash
  end

  def _test_plans_search(request_data)
    if request_data['id'] == nil \
       && request_data['product_id'] == nil \
       && request_data['name'] == nil 
      response_hash = {}                 
      response_hash["message"] = "No search parameters provided. One or more of the following are required: "\
                                 "'product_id', 'name', 'id', and optionally 'deprecated'"
      return {'response' => response_hash,
              'status' => 400}   
    end     
    conditions = {:id => request_data['id'],
                  :product_id => request_data['product_id'],
                  :name => request_data['name'],
                  :deprecated => request_data['deprecated']}                  
    conditions.delete_if {|k,v| v.blank?}    
    test_plans = TestPlan.find(:all, :conditions => conditions, :order => "id ASC")     
    if test_plans == []
      response_hash = {
        'response' => {'message' => "No Test Plan(s) found. Try searching based on another parameter.",
                       'found' => false},
        'status' => 200         
      }           
    else 
      test_plans_map = 
        test_plans.map do |tp|
          { 'id' => tp[:id],
            'name' => tp[:name],
            'description' => tp[:description],
            'product_id' => tp[:product_id],
            'status' => (I18n.t :item_status)[tp[:status]],
            'version' => tp[:version],
            'parent_id' => tp[:parent_id],
            'deprecated' => tp[:deprecated],
            'created_by_id' => tp[:created_by_id],
            'modified_by_id' => tp[:modified_by_id],
            'created_at' => tp[:created_at],
            'updated_at' => tp[:updated_at],
            'custom_fields' => _get_custom_fields('test_plan', tp),
            'test_cases' => get_test_plan_cases(tp) }
        end
      response_hash = {
        'response' => {'message' => "Test Plan(s) found.",
                       'test_plans' => test_plans_map,
                       'found' => true},
        'status' => 200         
      }        
    end  
    return response_hash    
  end
  
  def _test_plans_create_new_version(test_plan, clone_plan_cases=true)
    # Find the parent test plan ID
    original_test_plan = test_plan
    parent_id = view_context.find_test_plan_parent_id(original_test_plan) 
    # Find the current max version for this parent id
    max_version = TestPlan.where( "id = ? OR parent_id = ?", parent_id, parent_id ).maximum(:version)         
    # clone the test case
    test_plan = original_test_plan.dup
    # Remember to increate the version value
    test_plan.version = max_version + 1
    test_plan.parent_id = parent_id
    test_plan.save     
    # Make a clone of each case for this test plan
    if clone_plan_cases
      original_test_plan.plan_cases.each do |plan_case|
        new_plan_case = plan_case.dup
        new_plan_case.test_plan_id = test_plan.id
        new_plan_case.save
      end
    end
    # Make a clone of each custom field for this test plan
    original_test_plan.custom_items.each do |item|
      new_item = item.dup
      new_item.test_plan_id = test_plan.id
      new_item.save
    end           
    # Mark the earlier test plan as deprecated
    original_test_plan.deprecated = true        
    original_test_plan.save
    return test_plan  
  end

  def _handle_plancases(test_plan, test_cases)
    if test_cases.is_a?(Array) \
       && !test_cases.empty?       
       plancases = PlanCase.where(:test_plan_id => test_plan.id).order(case_order: :asc)
       if !plancases.empty?
          ordered_test_cases = plancases.map do |pc|
            pc[:test_case_id]
          end
          if test_cases.count == ordered_test_cases.count \
             && test_cases == ordered_test_cases
             return true, test_plan, nil
          else
            test_plan = _test_plans_create_new_version(test_plan, false)
            test_plan.save
            test_plan.reload            
          end
        end
        test_cases.each_with_index do|test_case_id, i|                  
          test_case = TestCase.where(:id => test_case_id).first
          if !test_case.nil?                                                      
            plancase = PlanCase.new(:test_plan_id => test_plan.id,
                                    :test_case_id => test_case_id,
                                    :case_order => i)   
            test_plan.plan_cases << plancase
          else
            return false, nil, 'No test case with id "%s" was found' %[test_case_id]          
          end          
        end
        test_plan.save
        return true, test_plan, nil
    else
      return false, nil, 'Passed test_cases parameter was empty or not an array.' 
    end  
  end

  def _test_plans_create(request_data)
    if request_data['new_version']
      request_data['deprecated'] = 0
    end
    response_hash = _test_plans_search({'id' => request_data['id'],
                                       'name' => request_data['name'],
                                       'product_id' => request_data['product_id'],
                                       'deprecated' => request_data['deprecated']})                                      
    if response_hash["status"] == 200 
      if response_hash['response']['found']
        if request_data['new_version']
          test_plan = TestPlan.where(:id => response_hash['response']['test_plans'].first['id']).first
          test_plan = _test_plans_create_new_version(test_plan)
          test_plan_custom_fields = _get_custom_fields('test_plan', test_plan)
          plan_cases = get_test_plan_cases(test_plan)                      
          response_hash = {
            'response' => {'message' => 'Successfully created new test plan version',
                           'id' => test_plan.id,
                           'name' => test_plan.name,
                           'description' => test_plan.description,
                           'version' => test_plan.version,
                           'parent_id' => test_plan.parent_id ? test_plan.parent_id : nil,
                           'product_id' => test_plan.product_id,
                           'custom_fields' => test_plan_custom_fields,
                           'status' => (I18n.t :item_status)[test_plan.status],
                           'test_cases' => plan_cases                     
                           },
            'status' => 201
          }                             
        end
      else
        if request_data['new_version']
          return {'response' => {'message' => 'No test plan found to create new version from.'},
                  'status' => 400}                            
        end       
        response_hash = _products_search({'id' => request_data['product_id'],
                                          'indirect_call' => true})        
        if !(response_hash["status"] == 200 && response_hash['response']['found'])
          response_hash['status'] = 400
          return response_hash
        end              
        if request_data['name'] == nil
          return {'response' => {'message' => 'No name provided.'},
                  'status' => 400}   
        end        
        created_by_id = request_data['created_by_id']
        if created_by_id
          response_hash = _users_search({'id' => created_by_id})
          if !response_hash['response']['found']
            response_hash["status"] = 400
            return response_hash
          end          
        end        
        status, message = _get_status(request_data)
        if !status
          return {'response' => {'message' => message},
                  'status' => 400}          
        end                
        test_plan = TestPlan.new(:product_id => request_data['product_id'],
                                 :name => request_data['name'],
                                 :status => status,
                                 :description => request_data['description'],
                                 :created_by_id => created_by_id != nil ? created_by_id : 1)
        # handle custom fields if any  
        if request_data.key?('custom_fields')
          success, message = _handle_custom_fields(request_data, "test_plan", test_plan)
          if !success
            response_hash = {
              'response' => {'message' => message},
              'status' => 400
            }           
            return response_hash   
          end
        end                  
        if test_plan.save
          if request_data['test_cases']       
            success, test_plan, message = _handle_plancases(test_plan, request_data['test_cases'])
            if !success
              return {'response' => {'message' => message},
                      'status' => 400} 
            end
          end
          test_plan.reload
          test_plan_custom_fields = _get_custom_fields('test_plan', test_plan)
          plan_cases = get_test_plan_cases(test_plan)                           
          response_hash = {
            'response' => {'message' => 'Successfully created test plan.',
                           'id' => test_plan.id,
                           'name' => test_plan.name,
                           'description' => test_plan.description,
                           'version' => test_plan.version,
                           'parent_id' => test_plan.parent_id ? test_plan.parent_id : nil,
                           'product_id' => test_plan.product_id,
                           'custom_fields' => test_plan_custom_fields,
                           'status' => (I18n.t :item_status)[test_plan.status],
                           'test_cases' => plan_cases                        
                           },
            'status' => 201
          }                    
        else
          response_hash = {
            'response' => {'message' => 'Error creating test plan'},
            'status' => 500
          }           
        end             
      end    
    end    
    return response_hash
  end

  def _test_plans_update(request_data)
    if request_data['to_update'] == nil \
       && request_data['new_values'] == nil
      return {'response' => {'message' => "No to_update or new_values passed."},
              'status' => 400}   
    end     
    response_hash = _test_plans_search({'id' => request_data['to_update']['id'],
                                       'name' => request_data['to_update']['name'],
                                       'product_id' => request_data['to_update']['product_id'],
                                       'deprecated' => request_data['to_update']['deprecated']})
    if response_hash["status"] == 200 && response_hash['response']['found'] 
      test_plan = TestPlan.where(:id => response_hash['response']['test_plans'].first['id']).first  
      test_plan.name = request_data['new_values']['name'] || test_plan.name
      test_plan.description = request_data['new_values']['description'] || test_plan.description
      if request_data['new_values']['product_id']
        response_hash = _products_search({'name' => request_data['new_values']['product_name'],
                                          'id' => request_data['new_values']['product_id'],
                                          'indirect_call' => true})        
        if !(response_hash["status"] == 200 && response_hash['response']['found']) 
          return response_hash
        end
        test_plan.product_id = request_data['new_values']['product_id']    
      end
      status, message = _get_status(request_data['new_values'])
      if !status
        return {'response' => {'message' => message},
                'status' => 400}          
      end
      test_plan.status = status
      created_by_id = request_data['new_values']['created_by_id']
      if created_by_id
        response_hash = _users_search({'id' => created_by_id})
        if !response_hash['response']['found']
          response_hash["status"] = 400
          return response_hash
        end 
        test_plan.created_by_id = created_by_id         
      end         
      # handle custom fields if any
      if request_data['new_values']['overwrite_custom_fields']
        test_plan.custom_fields.destroy_all
      end        
      if request_data['new_values'].key?('custom_fields')
        success, message = _handle_custom_fields(request_data['new_values'], "test_plan", test_plan)
        if !success
          response_hash = {
            'response' => {'message' => message},
            'status' => 400
          }           
          return response_hash   
        end
      end                          
      if test_plan.save
        if request_data['new_values']['test_cases']       
          success, test_plan, message = _handle_plancases(test_plan, request_data['new_values']['test_cases'])
          if !success
            return {'response' => {'message' => message},
                    'status' => 400} 
          end
        end
        test_plan.reload
        test_plan_custom_fields = _get_custom_fields('test_plan', test_plan)
        plan_cases = get_test_plan_cases(test_plan)                
        response_hash = {
          'response' => {'message' => 'Successfully updated test plan.',
                         'id' => test_plan.id,
                         'name' => test_plan.name,
                         'description' => test_plan.description,
                         'version' => test_plan.version,
                         'parent_id' => test_plan.parent_id ? test_plan.parent_id : nil,
                         'product_id' => test_plan.product_id,
                         'custom_fields' => test_plan_custom_fields,
                         'status' => (I18n.t :item_status)[test_plan.status],
                         'test_cases' => plan_cases                        
                         },
          'status' => 200
        }                       
      else
        response_hash = {
          'response' => {'message' => 'Error updating test plan.'},
          'status' => 500
        }           
      end
    end
    return response_hash
  end

  def get_stencil_test_plans(stencil)    
    stencil_test_plans = stencil.stencil_test_plans.map do |s|
      { stencil_test_plan_id: s[:id],
        stencil_id: s[:stencil_id],
        test_plan_id: s[:test_plan_id],
        device_id: s[:device_id],
        plan_order: s[:plan_order] }
    end
    return stencil_test_plans 
  end

  def _stencils_search(request_data)
    if request_data['id'] == nil \
       && request_data['product_id'] == nil \
       && request_data['name'] == nil 
      response_hash = {}                 
      response_hash["message"] = "No search parameters provided. One or more of the following are required: "\
                                 "'product_id', 'name', 'id', and optionally 'deprecated'"
      return {'response' => response_hash,
              'status' => 400}   
    end
    conditions = {:id => request_data['id'],
                  :product_id => request_data['product_id'],
                  :name => request_data['name'],
                  :deprecated => request_data['deprecated']}                  
    conditions.delete_if {|k,v| v.blank?}    
    stencils = Stencil.find(:all, :conditions => conditions, :order => "id ASC")     
    if stencils == []
      response_hash = {
        'response' => {'message' => "No Stencil(s) found. Try searching based on another parameter.",
                       'found' => false},
        'status' => 200         
      }           
    else     
      stencils_map = 
        stencils.map do |s|
          { 'id' => s[:id],
            'name' => s[:name],
            'description' => s[:description],
            'product_id' => s[:product_id],
            'status' => (I18n.t :item_status)[s[:status]],
            'version' => s[:version],
            'parent_id' => s[:parent_id],
            'deprecated' => s[:deprecated],
            'created_by_id' => s[:created_by_id],
            'modified_by_id' => s[:modified_by_id],
            'created_at' => s[:created_at],
            'updated_at' => s[:updated_at],
            'custom_fields' => _get_custom_fields('stencil', s),
            'test_plans' => get_stencil_test_plans(s) }
        end
      response_hash = {
        'response' => {'message' => "Stencils(s) found.",
                       'stencils' => stencils_map,
                       'found' => true},
        'status' => 200         
      }        
    end  
    return response_hash 
  end

  def _stencils_create_new_version(stencil, clone_test_plans=true)
    # Find the parent stencil ID
    original_stencil = stencil
    parent_id = view_context.find_stencil_parent_id(original_stencil) 
    # Find the current max version for this parent id
    max_version = Stencil.where( "id = ? OR parent_id = ?", parent_id, parent_id ).maximum(:version)         
    # clone the test case
    stencil = original_stencil.dup
    # Remember to increate the version value
    stencil.version = max_version + 1
    stencil.parent_id = parent_id
    stencil.save
    if clone_test_plans  
      # Make a clone of each test plan for this stencil
      original_stencil.stencil_test_plans.each do |stencil_test_plan|
        new_stencil_test_plan = stencil_test_plan.dup
        new_stencil_test_plan.stencil_id = stencil.id
        new_stencil_test_plan.save
      end
    end                    
    # Mark the earlier stencil as deprecated
    original_stencil.deprecated = true        
    original_stencil.save
    return stencil     
  end

  def _handle_stencil_test_plans(stencil, test_plans, new_version=true) 
    if test_plans.is_a?(Array) \
       && !test_plans.empty?       
       incorrect_fields = test_plans.map {|x| (x.is_a?(Hash) && !x.empty?) ? nil : x.to_s}.compact
       if incorrect_fields.count > 0
         return false, nil, "One or more passed test_plans were not of the correct type or empty"
       end              
       stencil_test_plans = StencilTestPlan.where(:stencil_id => stencil.id).order(plan_order: :asc)       
       if !stencil_test_plans.empty?         
          ordered_test_plans = stencil_test_plans.map do |stp|
            {'id' => stp[:test_plan_id],
             'device_id' => stp[:device_id]}
          end        
          if test_plans.count == ordered_test_plans.count
            equal = true
            test_plans.each_with_index do|tp, i| 
              if tp != ordered_test_plans[i]
                equal = false
                break
              end
            end
            return true, stencil, nil if equal
          end
          if new_version
            stencil = _stencils_create_new_version(stencil, false)
          else
            stencil.stencil_test_plans.delete_all
          end
          stencil.save
          stencil.reload                        
        end
        test_plans.each_with_index do|tp, i|                             
          if !(tp.key?('id') && tp.key?('device_id'))
            return false, nil, 'Passed test plan "%s" did not contain both a id and device_id key' %[tp] 
          end                 
          test_plan = TestPlan.where(:id => tp['id']).first
          if test_plan.nil?
            return false, nil, 'No test plan with id "%s" was found' %[tp['id']]
          end
          device = Device.where(:id => tp['device_id']).first
          if device.nil?
            return false, nil, 'No device with id "%s" was found' %[tp['device_id']]
          end          
          if !test_plan.nil?                                                      
            stencil_test_plan = StencilTestPlan.new(:stencil_id => stencil.id,
                                                    :test_plan_id => tp['id'],
                                                    :device_id => tp['device_id'],
                                                    :plan_order => i)   
            stencil.stencil_test_plans << stencil_test_plan                      
          end          
        end
        stencil.save
        return true, stencil, nil
    else
      return false, nil, 'Passed test_plans parameter was empty or not an array.' 
    end  
  end

  def _stencils_create(request_data)
    if request_data['new_version']
      request_data['deprecated'] = 0
    end
    response_hash = _stencils_search({'id' => request_data['id'],
                                      'name' => request_data['name'],
                                      'product_id' => request_data['product_id'],
                                      'deprecated' => request_data['deprecated']})                                      
    if response_hash["status"] == 200    
      if response_hash['response']['found']        
        if request_data['new_version'] 
          stencil = Stencil.where(:id => response_hash['response']['stencils'].first['id']).first
          stencil = _stencils_create_new_version(stencil)         
          stencil_test_plans = get_stencil_test_plans(stencil)                   
          response_hash = {
            'response' => {'message' => 'Successfully created new stencil version',
                           'id' => stencil.id,
                           'name' => stencil.name,
                           'description' => stencil.description,
                           'version' => stencil.version,
                           'parent_id' => stencil.parent_id ? stencil.parent_id : nil,
                           'product_id' => stencil.product_id,
                           'test_plans' => stencil_test_plans,
                           'status' => (I18n.t :item_status)[stencil.status],                      
                           },
            'status' => 201
          }                                  
        end
      else        
        if request_data['new_version']
          return {'response' => {'message' => 'No stencil found to create new version from'},
                  'status' => 400}                            
        end
        response_hash = _products_search({'id' => request_data['product_id'],
                                          'indirect_call' => true})        
        if !(response_hash["status"] == 200 && response_hash['response']['found'])
          response_hash['status'] = 400
          return response_hash
        end     
        if request_data['name'] == nil
          return {'response' => {'message' => 'No name provided.'},
                  'status' => 400}   
        end       
        created_by_id = request_data['created_by_id']
        if created_by_id
          response_hash = _users_search({'id' => created_by_id})
          if !response_hash['response']['found']
            response_hash["status"] = 400
            return response_hash
          end          
        end
        status, message = _get_status(request_data)
        if !status
          return {'response' => {'message' => message},
                  'status' => 400}          
        end           
        stencil = Stencil.new(:product_id => request_data['product_id'],
                              :name => request_data['name'],
                              :status => status,
                              :description => request_data['description'],
                              :created_by_id => created_by_id != nil ? created_by_id : 1)                                                                           
        if stencil.save
          if request_data['test_plans']       
            success, stencil, message = _handle_stencil_test_plans(stencil, request_data['test_plans'])
            if !success
              return {'response' => {'message' => message},
                      'status' => 400} 
            end
          end 
          stencil.reload         
          stencil_test_plans = get_stencil_test_plans(stencil)                           
          response_hash = {
            'response' => {'message' => 'Successfully created stencil.',
                           'id' => stencil.id,
                           'name' => stencil.name,
                           'description' => stencil.description,
                           'version' => stencil.version,
                           'parent_id' => stencil.parent_id ? stencil.parent_id : nil,
                           'product_id' => stencil.product_id,
                           'test_plans' => stencil_test_plans,
                           'status' => (I18n.t :item_status)[stencil.status]                        
                           },
            'status' => 201
          }                    
        else
          response_hash = {
            'response' => {'message' => 'Error creating stencil'},
            'status' => 500
          }           
        end             
      end    
    end    
    return response_hash
  end

  def _stencils_update(request_data)
    if request_data['to_update'] == nil \
       && request_data['new_values'] == nil
      return {'response' => {'message' => "No to_update or new_values passed."},
              'status' => 400}   
    end    
    response_hash = _stencils_search({'id' => request_data['to_update']['id'],
                                      'name' => request_data['to_update']['name'],
                                      'product_id' => request_data['to_update']['product_id'],
                                      'deprecated' => request_data['to_update']['deprecated']})                                       
    if response_hash["status"] == 200 && response_hash['response']['found']
      stencil = Stencil.where(:id => response_hash['response']['stencils'].first['id']).first     
      stencil.name = request_data['new_values']['name'] || stencil.name
      stencil.description = request_data['new_values']['description'] || stencil.description     
      if request_data['new_values']['product_id']
        response_hash = _products_search({'name' => request_data['new_values']['product_name'],
                                          'id' => request_data['new_values']['product_id'],
                                          'indirect_call' => true})        
        if !(response_hash["status"] == 200 && response_hash['response']['found']) 
          return response_hash
        end
        stencil.product_id = request_data['new_values']['product_id']    
      end         
      status, message = _get_status(request_data['new_values'])
      if !status
        return {'response' => {'message' => message},
                'status' => 400}          
      end
      stencil.status = status 
      created_by_id = request_data['new_values']['created_by_id']
      if created_by_id
        response_hash = _users_search({'id' => created_by_id})
        if !response_hash['response']['found']
          response_hash["status"] = 400
          return response_hash
        end 
        stencil.created_by_id = created_by_id         
      end                               
      if stencil.save
        if request_data['new_values']['test_plans']
          new_version = request_data.key?('new_version') ? request_data['new_version'] : true                  
          success, stencil, message = _handle_stencil_test_plans(stencil, request_data['new_values']['test_plans'], new_version)
          if !success
            return {'response' => {'message' => message},
                    'status' => 400} 
          end
        end        
        stencil.reload
        stencil_test_plans = get_stencil_test_plans(stencil)             
        response_hash = {
          'response' => {'message' => 'Successfully updated stencil',
                         'id' => stencil.id,
                         'name' => stencil.name,
                         'description' => stencil.description,
                         'version' => stencil.version,
                         'parent_id' => stencil.parent_id ? stencil.parent_id : nil,
                         'product_id' => stencil.product_id,
                         'test_plans' => stencil_test_plans,
                         'status' => (I18n.t :item_status)[stencil.status]                         
                         },
          'status' => 200
        }                       
      else
        response_hash = {
          'response' => {'message' => 'Error updating stencil'},
          'status' => 500
        }           
      end
    end
    return response_hash
  end

  def _assignments_search(request_data)
    response_hash = {}  
    if request_data['id'] == nil \
       && request_data['product_id'] == nil \
       && request_data['test_plan_id'] == nil \
       && request_data['stencil_id'] == nil 
      response_hash["message"] = "No search parameters provided. id and product_id " \
                                 "are required along with either stencil_id or test_plan_id"
      return {'response' => response_hash,
              'status' => 400}   
    end
    conditions = {:id => request_data['id'],
                  :product_id => request_data['product_id'],
                  :version_id => request_data['product_version_id'],
                  :test_plan_id => request_data['test_plan_id'],
                  :stencil_id => request_data['stencil_id']}
    conditions.delete_if {|k,v| v.blank?}    
    assignments = Assignment.find(:all, :conditions => conditions, :order => "id ASC")    
    if assignments != []
      response_hash["assignments"] = 
        assignments.map do |a|
          { id: a[:id],
            product_id: a[:product_id],
            test_plan_id: a[:test_plan_id],
            stencil_id: a[:stencil_id],            
            schedule_id: a[:schedule_id],
            product_version_id: a[:version_id],
            notes: a[:notes],
            created_at: a[:created_at],
            updated_at: a[:updated_at],
            custom_fields: _get_custom_fields('assignment', a),
            results: a.results }
        end                                                    
      response_hash["message"] = "Assignment(s) found."
      response_hash["found"] = true
    else
      response_hash["message"] = "No assignments(s) found. Try searching based on another parameter."
      response_hash["found"] = false
    end
    return {'response' => response_hash,
            'status' => 200}    
  end
   
  def _assignments_create(request_data)    
    response_hash = _versions_search({'id' => request_data['product_version_id'],
                                      'version' => request_data['product_version'],
                                      'product_name' => request_data['product_name'],
                                      'product_id' => request_data['product_id'],
                                      'indirect_call' => true})                                       
    if !(response_hash["status"] == 200 && response_hash['response']['found'])
      response_hash['status'] = 400
      return response_hash
    end
    product_id = response_hash['response']['versions'].last['product_id']
    version_id = response_hash['response']['versions'].last['id']    
    template_type = nil
    test_plan_id = nil
    stencil_id = nil
    if request_data['test_plan_id'].nil? && request_data['stencil_id'].nil?
      return {'response' => {'message' => "No 'test_plan_id' or 'stencil_id' provided."},
              'status' => 400}
    elsif request_data['test_plan_id'] != nil
      response_hash = _test_plans_search({'id' => request_data['test_plan_id'],
                                         'name' => request_data['test_plan_name'],
                                         'product_id' => request_data['product_id'],
                                         'deprecated' => request_data['deprecated']})
      template_type = 'test_plan'      
    else
      response_hash = _stencils_search({'id' => request_data['stencil_id'],
                                        'name' => request_data['stencil_name'],
                                        'product_id' => request_data['product_id'],
                                        'deprecated' => request_data['deprecated']})      
      template_type = 'stencil'
    end    
    if response_hash["status"] == 200 && response_hash['response']['found']      
      if template_type == 'test_plan'          
        assignment = Assignment.new(:product_id => product_id,
                                    :version_id => version_id,
                                    :test_plan_id => response_hash['response']['test_plans'][0]['id'],
                                    :notes => request_data['notes'])
      else       
        assignment = Assignment.new(:product_id => product_id,
                                    :version_id => version_id,
                                    :stencil_id => response_hash['response']['stencils'][0]['id'],
                                    :notes => request_data['notes'])                                          
      end
      # handle custom fields if any
      if request_data.key?('custom_fields')
        success, message = _handle_custom_fields(request_data, "assignment", assignment)
        if !success
          return {'response' => {'message' => message},
                  'status' => 400}   
        end
      end
      if assignment.save
        if template_type == 'test_plan'
          assignment.test_plan.test_cases.each do |tc|
            assignment.results.create(:test_case_id => tc.id)
          end          
        else         
          assignment.stencil.stencil_test_plans.each do |stencil_test_plan|
            stencil_test_plan.test_plan.plan_cases.order('case_order').each do |plan_case|
              assignment.results.create(:test_case_id => plan_case.test_case_id,
                                        :device_id => stencil_test_plan.device_id )
            end
          end          
        end 
        assignment.reload                      
        response_hash = {
          'response' => {'message' => 'Successfully created assignment',
                         'id' => assignment.id,
                         'product_id' => assignment.product_id,
                         'test_plan_id' => assignment.test_plan_id,
                         'stencil_id' => assignment.stencil_id,
                         'schedule_id' => assignment.schedule_id,
                         'product_version_id' => assignment.version_id,
                         'notes' => assignment.notes,
                         'created_at' => assignment.created_at,
                         'updated_at' => assignment.updated_at,
                         'custom_fields' => _get_custom_fields('assignment', assignment),
                         'results' => assignment.results                          
                         },
          'status' => 201
        }           
      else
        response_hash = {
          'response' => {'message' => 'Error creating assignment.'},
          'status' => 500
        }          
      end                                                    
    else
      response_hash['status'] = 400      
    end 
    return response_hash
  end

  def _results_get(request_data)
    response_hash = {}  
    if request_data['id'] == nil \
       && request_data['assignment_id'] == nil \
       && request_data['device_id'] == nil \
       && request_data['test_case_id'] == nil
      response_hash["message"] = "No search parameters provided. Please provide one or more of the following: " \
                                 "id, assignment_id, device_id, test_case_id"
      return {'response' => response_hash,
              'status' => 400}   
    end
    conditions = {:id => request_data['id'],
                  :assignment_id => request_data['assignment_id'],
                  :device_id => request_data['device_id'],
                  :test_case_id => request_data['test_case_id']}
    conditions.delete_if {|k,v| v.blank?}    
    results = Result.find(:all, :conditions => conditions, :order => "id ASC")
    if results != []
      results_map = 
        results.map do |result|
          {'id' => result.id,
          'assignment_id' => result.assignment_id,
          'test_case_id' => result.test_case_id,
          'result' => result.result,
          'note' => result.note,
          'created_at' => result.created_at,
          'updated_at' => result.updated_at,
          'executed_at' => result.executed_at,
          'bugs' => result.bugs,
          'device_id' => result.device_id,
          'custom_fields' => _get_custom_fields('result', result)}
        end
      response_hash["results"] = results_map                                                   
      response_hash["message"] = "Result(s) found."
      response_hash["found"] = true
    else
      response_hash["message"] = "No result(s) found. Try searching based on another parameter."
      response_hash["found"] = false
    end
    return {'response' => response_hash,
            'status' => 200}       
  end

  def _results_set(request_data)
    if !request_data.key?('results')
      return {'response' => {'message' => 'No results passed to be set.'},
              'status' => 400}       
    end
    if request_data['results'].is_a?(Hash) \
       && !request_data['results'].empty?
      incorrect_fields = request_data['results'].map {|k,v| (v.is_a?(Hash) && !v.empty?) ? nil : k.to_s}.compact
      if incorrect_fields.count > 0        
        return {'response' => {'message' => 'One or more passed results were not of the correct type or empty.'},
                'status' => 400}        
      end               
      response_hash = {'results' => []}
      request_data['results'].each do |key, value| 
        if !value.key?('result')
          return {'response' => {'message' => 'Passed result with id %s did not contain a result element.' %[key]},
                  'status' => 400}         
        end
        executed_at = value['executed_at']
        test_state = value['result']
        bugs = value['bugs']      
        # set executed_at if provided
        if executed_at == nil
          executed_at = DateTime.now
        elsif executed_at !~ /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/
          return {'response' => {'message' => "Invalid date time format provided for executed_at. " \
                                              "Must be in yyyy-mm-dd hh:mm:ss format or blank to use current date time."},
                  'status' => 400}
        end

        # Check that value is a valid Result
        test_state = test_state.downcase.titleize
        if test_state != "Passed" && test_state != "Failed" && test_state !="Blocked"
          return {'response' => {'message' => "Invalid result provided in request. Must specify Passed, Failed, or Blocked."},
                  'status' => 400}
        end

        result = Result.where(:id => key).first
        if result.nil?
          return {'response' => {'message' => "No result with id %s found" %[key]},
                  'status' => 400}          
        end
        if !result.result.nil?
          return {'response' => {'message' => "Result with id %s has already been set." %[key]},
                  'status' => 400}          
        end
        previous_result = Result.where("assignment_id < :assignment_id AND test_case_id = :test_case_id AND device_id = :device_id",
                                       {:assignment_id => result.assignment_id,
                                        :test_case_id => result.test_case_id,
                                        :device_id => result.device_id}).order("assignment_id DESC").first
        result.result = test_state
        result.executed_at = executed_at
        # if bugs passed in, add them to the result
        if bugs != nil
           trimmed_bugs = bugs.gsub(/\s+/, "")      
           if !trimmed_bugs.empty?
              result.bugs = trimmed_bugs
           end  
        end
        # if there is a previous result of this test
        # and it had any bugs, if the bugs are still open
        # add them to the next result automatically
        if previous_result != nil
          bug_results = view_context.list_bug_status( [previous_result] )
          if bug_results != nil
            open_bugs = []
            bug_results.sort.each do |key, value|
              issue_status = value[:status]
              # Redmine
              if Setting.value('Ticket System') == 'Redmine'
                if issue_status != "Closed" && issue_status != "Rejected"
                  open_bugs.push(key)
                end
              end
            end
            # add bugs to new result if any open
            if open_bugs.length
              if result.bugs != nil
                result.bugs += "," + open_bugs.join(",")
              else
                result.bugs = open_bugs.join(",")
              end
            end
          end
        end
        # handle custom fields if any
        if value.key?('custom_fields')
          success, message = _handle_custom_fields(value, "result", result)
          if !success
            return {'response' => {'message' => 'Error creating custom fields for result with id %s. ' \
                                                'Returned with message: %s' %[key, message]},
                    'status' => 400}     
          end
        end
        result.save
        result_map = {
          'id' => result.id,
          'assignment_id' => result.assignment_id,
          'test_case_id' => result.test_case_id,
          'result' => result.result,
          'note' => result.note,
          'created_at' => result.created_at,
          'updated_at' => result.updated_at,
          'executed_at' => result.executed_at,
          'bugs' => result.bugs,
          'device_id' => result.device_id,
          'custom_fields' => _get_custom_fields('result', result)
        }      
        response_hash['results'].push(result_map)
      end
      response_hash["message"] = "Result state(s) successfully set."
      return {'response' => response_hash,
              'status' => 200}     
    else
      return {'response' => {'message' => 'Passed results list was empty or invalid.'},
              'status' => 400}
    end
  end

  def _attachments_handler(request_data, action)     
    if request_data.key?('attachments')
      if request_data['attachments'].is_a?(Array) \
         && !request_data['attachments'].empty?
        incorrect_fields = request_data['attachments'].map {|x| (x.is_a?(Hash) && !x.empty?) ? nil : x}.compact
        if incorrect_fields.count > 0        
          return {'response' => {'message' => 'One or more passed attachments were not of the correct type or empty.'},
                  'status' => 400}        
        end       
        response_hash = {'attachments' => []}
        request_data['attachments'].each do |value|
          if action == 'upload'
            result = _attachments_upload(value)
            response_hash['message'] = 'Successfully uploaded all attachments'
          elsif action == 'update'
            result = _attachments_update(value)
            response_hash['message'] = 'Successfully updated all attachments'
          elsif action == 'delete'
            result = _attachments_delete(value)
            response_hash['message'] = 'Successfully deleted all attachments'            
          end
          if result['status'] == 200 || result['status'] == 201
            response_hash['attachments'].push(result['response'])
          else
            return result
          end          
        end
        return {'response' => response_hash,
                'status' => 200}    
      else
        return {'response' => {'message' => 'Passed attachments list was empty or invalid.'},
                'status' => 400}
      end
    else
      case action      
      when 'upload'
        return _attachments_upload(request_data)
      when 'update'
        return _attachments_update(request_data)        
      when 'delete'
        return _attachments_delete(request_data)
      end
    end      
  end

  def _attachments_search(request_data, download=false)
    response_hash = {}  
    if request_data['description'] == nil \
       && request_data['id'] == nil \
       && request_data['file_name'] == nil \
       && request_data['content_type'] == nil \
       && request_data['parent_id'] == nil \
       && request_data['parent_type'] == nil
      response_hash["message"] = "No search parameters provided. Please specify one or more of the following: " \
                                 "'id', 'description', 'file_name', 'content_type', 'parent_id', 'parent_type'"
      return {'response' => response_hash,
              'status' => 400}   
    end
    conditions = {:description => request_data['description'],
                  :id => request_data['id'],
                  :upload_file_name => request_data['file_name'],
                  :upload_content_type => request_data['upload_content_type'],
                  :uploadable_id => request_data['parent_id'],
                  :uploadable_type => request_data['parent_type'] }
    conditions.delete_if {|k,v| v.blank? }    
    uploads = Upload.find(:all, :conditions => conditions)
    if uploads != []
      response_hash["attachments"] = 
        uploads.map do |u|
          { id: u[:id],
            description: u[:description],
            parent_id: u.uploadable_id,
            parent_type: u.uploadable_type,
            file_name: u.upload_file_name,
            content_type: u.upload_content_type,
            size: u.upload_file_size,
            data: (Base64.encode64(File.read(u.upload.path)) if download),
            created_at: u.created_at,
            updated_at: u.updated_at }.reject{ |k,v| v.nil? }
        end      
      response_hash["message"] = "Attachments(s) found."
      response_hash["found"] = true
    else
      response_hash["message"] = "No attachments(s) found. Try searching based on another parameter."
      response_hash["found"] = false
    end
    return {'response' => response_hash,
            'attachment' => uploads.first,
            'status' => 200}    
  end

  def _attachments_upload(request_data)
    if request_data['description'].nil? || request_data['file_name'].nil? || request_data['data'].nil? \
       || request_data['parent_type'].nil? || request_data['parent_id'].nil?
      response_hash = {"message" => "No description, file_name, content_type, parent_type, parent_id, or data parameter provided."}
      return {'response' => response_hash,
              'status' => 400}
    end
    request_data['parent_type'] = request_data['parent_type'].titleize 
    # only allow Result attachments for now
    if request_data['parent_type'] != "Result"
        return {'response' => {'message' => "Currently, only Result attachment uploads are supported via the web api. Please specify 'Result'" \
                                            " as the 'parent_type' and a valid Result object id for 'parent_id'."},
                'status' => 400}
    end
    # make sure the result object exists
    result = Result.where(:id => request_data['parent_id']).first
    if result.nil?
      return {'response' => {'message' => "No result with id %s found" %[request_data['parent_id']]},
              'status' => 400}          
    end
    begin
      temp_dir = Dir.mktmpdir
      temp_file = File.new('%s/%s' %[temp_dir, request_data['file_name']], 'w+')
      File.open(temp_file.path, 'wb') do |f|
          f.write Base64.decode64(request_data['data'])
      end
      upload = Upload.new(:description => request_data['description'],
                          :uploadable_id => request_data['parent_id'],
                          :uploadable_type => request_data['parent_type'])
      upload.upload = temp_file
      if upload.save
        response_hash = {
          'response' => {
            'message' => 'Attachment successfully uploaded.',
            'id' => upload.id,          
            'description' => upload.description,
            'file_name' => upload.upload_file_name,
            'content_type' => upload.upload_content_type,
            'size' => upload.upload_file_size,
            'parent_id' => upload.uploadable_id,
            'parent_type' => upload.uploadable_type,
            'created_at' => upload.created_at,
            'updated_at' => upload.updated_at
          },
          'status' => 201
        }        
      else
        response_hash = {
          'response' => {'message' => 'Error uploading attachment.  Make sure the data was Base64 encoded.'},
          'status' => 500
        }
      end
    ensure
      FileUtils.remove_entry temp_dir
    end
    return response_hash
  end

  def _attachments_update(request_data)
    if request_data['to_update'] == nil \
       && request_data['new_values'] == nil
      return {'response' => {'message' => "No to_update or new_values passed."},
              'status' => 400}
    end
    response_hash = _attachments_search(request_data['to_update'])
    if response_hash["status"] == 200 && response_hash['response']['found']
      attachment = response_hash['attachment']
      attachment.description = request_data['new_values']['description'] || attachment.description
      attachment.upload_content_type = request_data['new_values']['content_type'] || attachment.upload_content_type
      # only allow Result attachments for now
      if request_data['new_values']['parent_type'] && request_data['new_values']['parent_type'] != "Result"
          return {'response' => {'message' => "Currently, only Result attachment uploads are supported via the web api. Please specify 'Result'" \
                                              " as the 'parent_type' and a valid Result object id for 'parent_id'."},
                  'status' => 400}
      end      
      # make sure the result object exists
      result = Result.where(:id => request_data['new_values']['parent_id']).first
      if result.nil?
        return {'response' => {'message' => "No result with id %s found" %[request_data['new_values']['parent_id']]},
                'status' => 400}          
      end
      attachment.uploadable_id = request_data['new_values']['parent_id'] || attachment.uploadable_id
      if attachment.save
        attachment.reload           
        response_hash = {
          'response' => {'message' => 'Successfully updated attachment "%s" with id "%s".' \
                                      %[attachment.description, attachment.id],
                         'id' => attachment.id,          
                         'description' => attachment.description,
                         'file_name' => attachment.upload_file_name,
                         'content_type' => attachment.upload_content_type,
                         'size' => attachment.upload_file_size,
                         'parent_id' => attachment.uploadable_id,
                         'parent_type' => attachment.uploadable_type,
                         'created_at' => attachment.created_at,
                         'updated_at' => attachment.updated_at                       
                         },
          'status' => 200
        }                       
      else
        response_hash = {
          'response' => {'message' => 'Error updating attachment "%s" with id "%s".' \
                                      %[attachment.description, attachment.id]},
          'status' => 500
        }           
      end
    else
      response_hash['status'] = 400
      response_hash['response']['message'] += ' Failed to update using %s.' %[request_data['to_update']]
    end
    return response_hash            
  end

  def _attachments_delete(request_data)
    attachment = Upload.where(:id => request_data['id']).first
    if attachment.nil?
      return {'response' => {'message' => "No attachment with id %s found" %[request_data['id']]},
              'status' => 400}
    end
    attachment.destroy
    return {'response' => {'message' => 'Successfully deleted attachment with id "%s".' %[request_data['id']]},
            'status' => 200}    
  end

end
