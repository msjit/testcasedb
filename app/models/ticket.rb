require 'xmlrpc/client'
require 'soap/wsdlDriver'
require 'rexml/document'

# Bugzilla requests are performed using the xmlrpc client
# Jira uses Net:HTTP + JSON

class Ticket  
  def self.version
    settings = ticket_settings()
    
    if settings["system"] == 'Bugzilla'
      server = XMLRPC::Client.new2( settings["url"] )
      bugzilla = server.proxy('Bugzilla')
      return bugzilla.version
      
    elsif settings["system"] == 'Jira'
      # Build the URI
      # It is assumed that the URL fully includes the API path
      uri = URI(settings["url"] + 'serverInfo')
      # Build the requests
      req = Net::HTTP::Get.new(uri.request_uri)
      # Add authentication info
      req.basic_auth settings['username'], settings['password']
      # Enable ssl if uri starts with https
      if uri.scheme == "https"
        req.use_ssl = true
        # req.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      # Run the request
      result = Net::HTTP.start(uri.host, uri.port) {|http|
        http.request(req)
      }
      
      # Was there a 2xx pass result
      if Net::HTTPSuccess === result
        # Result is in json... break it down
        jsonResult = ActiveSupport::JSON.decode(result.body)
        # and return the version
        return jsonResult["version"]
      else
        return "ERROR"
      end

    elsif settings["system"] == 'Mantis'
      # Build the URL
      url = settings["url"] + 'api/soap/mantisconnect.php?wsdl'
      # Create the soap entity
      client = SOAP::WSDLDriverFactory.new(url).create_rpc_driver
      # Generate the request
      request = client.mc_version()
      #Return the version
      return request      

    elsif settings["system"] == 'Redmine'
      # There is no api command in mantis for this.
      # We simply inform users
      return "The Mantis API does not have a version command"
    end
    
  end

  # Takes an array of bug numbers
  def self.bug_status(ids)
    bug_status = {}
    settings = ticket_settings()
    
    # Using XML we can query all statuses at once
    if settings["system"] == 'Bugzilla'
      server = XMLRPC::Client.new2( settings["url"] )
      ok, result = server.call2("Bug.get", {:ids => ids, :include_fields => ['id', 'status', 'summary'], :Bugzilla_login => settings["username"], :Bugzilla_password => settings["password"] } )
    
      if ok  
        result["bugs"].each do |bug|
          bug_status[ bug["id"].to_s ] = { :status => bug["status"], :name => bug["summary"] }
        end
      else
        bug_status["error"] = true
        puts result.faultCode
        puts result.faultString
      end
  
    elsif settings["system"] == 'Jira'
      # Jira, need to query each bug one by one and add to hash
      ids.each do |id|
        # Build the URI
        # It is assumed that the URL fully includes the API path
        uri = URI(settings["url"] + 'issue/' + id)
        # Build the requests
        req = Net::HTTP::Get.new(uri.request_uri)
        # Add authentication info
        req.basic_auth settings['username'], settings['password']
        # Enable ssl if uri starts with https
        if uri.scheme == "https"
          req.use_ssl = true
          # req.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        # Run the request
        result = Net::HTTP.start(uri.host, uri.port) {|http|
          http.request(req)
        }
  
        # Was there a 2xx pass result
        if Net::HTTPSuccess === result
          # Result is in json... break it down
          jsonResult = ActiveSupport::JSON.decode(result.body)
          
          # and add the status to the hash
          bug_status[id] = { :status => jsonResult["fields"]["status"]["value"]["name"], :name => jsonResult["fields"]["summary"]["value"] }
        else
          bug_status["error"] = true
        end
      end
      
    elsif settings["system"] == 'Mantis'
      # Build the URL
      url = settings["url"] + 'api/soap/mantisconnect.php?wsdl'

      # There can be issues with initial contact, example, bad url.
      # We capture it here
      begin
        # Create the soap entity
        client = SOAP::WSDLDriverFactory.new(url).create_rpc_driver
      rescue
        bug_status["error"] = true
      end

      # Mantis, need to query each bug one by one and add to hash
      # Notice that we have one wisdldriver object
      ids.each do |id|
        request = nil
        # STart the request
        begin
          # Generate the issue get request
          request = client.mc_issue_get(settings['username'], settings['password'], id)
        # IF there is a soap error, we set error here
        rescue
          bug_status["error"] = true
        # Otherwise we record the value
        else
          bug_status[id] = {:status => request["status"]["name"], :name => request["summary"] }
        end
      end
      
    elsif settings["system"] == 'Redmine'
      # Mantis, need to query each bug one by one and add to hash
      ids.each do |id|
        # Build the URI
        # It is assumed that the URL fully includes the API path
        uri = URI(settings["url"] + 'issues/' + id + '.xml')
        # Build the requests
        req = Net::HTTP::Get.new(uri.request_uri)
        # Add authentication info
        req.basic_auth settings['username'], settings['password']
        # Enable ssl if uri starts with https
        if uri.scheme == "https"
          req.use_ssl = true
          # req.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        # Run the request
        result = Net::HTTP.start(uri.host, uri.port) {|http|
          http.request(req)
        }
  
        # Was there a 2xx pass result
        if Net::HTTPSuccess === result
          # Result is in xml... break it down
          xmlResult = REXML::Document.new(result.body)
          
          # and add the status to the hash
          # We need the value of name for the status element
          bug_status[id] = { :status => xmlResult.elements["//status"].attributes["name"], :name => xmlResult.elements["//subject"].text }
        else
          bug_status["error"] = true
        end
      end
    end

    return bug_status    
  end

  private 
  
  # Retrieves a list of ticket settings and returns a hash with URL, username, password
  def self.ticket_settings
    settings = {}
    settings["system"] = Setting.value('Ticket System')
    settings["username"] = Setting.value('Ticket System Username')
    settings["password"] = Setting.value('Ticket System Password')
    
    # For bugzilla we need to add the xmlrpc.cgi. It is the same for all systems
    # For other systems, not required
    if settings["system"] == 'Bugzilla' 
      settings["url"] = Setting.value('Ticket System Url') + "xmlrpc.cgi"
    else
      settings["url"] = Setting.value('Ticket System Url')
    end
    
    return settings
  end
end