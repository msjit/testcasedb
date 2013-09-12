class Schedule < ActiveRecord::Base
  attr_accessible :device_id, :product_id, :test_plan_id, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday, :start_time, :user_ids
  belongs_to :product
  belongs_to :test_plan
  belongs_to :device
  has_many :schedule_users
  has_many :users, :through => :schedule_users
  has_many :assignments
  
  validates :product_id, :presence => true
  validates :device_id, :presence => true
  validates :test_plan_id, :presence => true
  validates :start_time, :presence => true
  
  def self.jmeter (result)
    # Pull values from DB and set variables
    jmeter_params = get_jmeter_parameters()
    
    # Assuming there is an attachment
    unless result.test_case.uploads.first == nil
      # Copy test plan over
      scp_file(jmeter_params, result.test_case.uploads.first)
    
       # Log into host machine
       if jmeter_params[:certificate] == nil or jmeter_params[:certificate] == "" or jmeter_params[:certificate] == "none"
         LOGGER.info "Using the password method."
        exp = ExpectrCustom.new "ssh " + jmeter_params[:username] + "@" + jmeter_params[:hostname], :timeout => 60
        exp.expect /[Pp]assword\:/
        sleep(1)
        exp.send jmeter_params[:password] + "\r"
      else
        LOGGER.info "Using the certificate method."
        exp = ExpectrCustom.new "ssh -i " + jmeter_params[:certificate] + ' ' + jmeter_params[:username] + "@" + jmeter_params[:hostname], :timeout => 60
      end
      exp.expect /%|#|$/
      sleep(1)
    
      # Run the jMeter command. See next look for crucial timing
      exp.send "cd " + jmeter_params[:working_dir] + "\r"
      exp.expect /%|#|$/
      sleep(1)
      exp.send "java -jar " + jmeter_params[:application_path] + ' -n -t ' + result.test_case.uploads.first.upload.original_filename + "\r"
      exp.expect "Created the tree successfully"
      exp.expect "Starting the test"
    
      # WAit X minutes for this to pass. X defined in settings
      # We do this with a loop and keep trying
      minutes_elapsed = 0
      jmeter_finished = false
      while jmeter_finished == false
        match = exp.expect("end of run", recoverable = true)
        # If no match is found after timeout we receive nil
        if match == nil
          LOGGER.info "jMeter task not finished. Incrementing minute counter."
          minutes_elapsed += 1
          if minutes_elapsed >= jmeter_params[:max_run_time]
            LOGGER.warn "Timeout exceeded. Killing jMeter process."
            # Kill the process
            exp.send("\x3")
            jmeter_finished = true
            result.result = "Failed"
            result.note = "jMeter time out. Run time exceeded #{jmeter_params[:max_run_time]} minutes."
            result.bugs = ""
            result.executed_at = Time.now
            result.save
          end
        else
          exp.expect /%|#|$/
          jmeter_finished = true
        end
      end
      sleep(1)
      ##
      # END RUNNING JMETER
      ##
      # Add the jmeter log as an attachment to the result
      copy_file_to_result(result, jmeter_params, 'jmeter.log')
      # We need to import each specified result file.
      result.test_case.test_case_targets.each do |case_target|
        LOGGER.info "Importing #{case_target.filename}"
        copy_file_to_result(result, jmeter_params, case_target.filename)
      end
    
      ##
      # Cleanup
      ##
      # Remove the log file 
      exp.send "rm -v jmeter.log\r"
      exp.expect "removed"
      exp.expect /%|#|$/

      # Remove the test plan file
      exp.send "rm -v " + result.test_case.uploads.first.upload.original_filename + "\r"
      exp.expect "removed"
      exp.expect /%|#|$/
    
      # Remove any target files
      # Since in working dir don't neeed to check full path.
      # Will either be there or be delete from full path if given
      result.test_case.test_case_targets.each do |case_target|
        exp.send "rm -v " + case_target.filename + "\r"
        exp.expect "removed"
        exp.expect /%|#|$/
      end

      output = exp.discard

      begin
        self.analyze_results(result)
      rescue
        LOGGER.error "There was an error analyzing results. Result statistics not recorded."
      end
    
      if result.result == nil
        result.result = "Passed"
        result.note = "jMeter complete."
        result.bugs = ""
        result.executed_at = Time.now
        return_value = result.save
      end
    # If there is no test case. Mark as blocked and add explanation.
    else
      result.result = "Blocked"
      result.note = "jMeter test case blocked. The test case does not have an attachment."
      result.bugs = ""
      result.executed_at = Time.now
      return_value = result.save
    end
  end

  def self.sikuli(result)
    # Pull values from DB and set variables
    sikuli_params = get_sikuli_parameters()
    
    # Assuming there is an attachment
    unless result.test_case.uploads.first == nil
      # Copy test plan over
      scp_file(sikuli_params, result.test_case.uploads.first)
    
       # Log into host machine
       if sikuli_params[:certificate] == nil or sikuli_params[:certificate] == "" or sikuli_params[:certificate] == "none"
         LOGGER.info "Using the password method."
        exp = ExpectrCustom.new "ssh " + sikuli_params[:username] + "@" + sikuli_params[:hostname], :timeout => 60
        exp.expect /[Pp]assword\:/
        sleep(1)
        exp.send sikuli_params[:password] + "\r"
      else
        LOGGER.info "Using the certificate method."
        exp = ExpectrCustom.new "ssh -i " + sikuli_params[:certificate] + ' ' + sikuli_params[:username] + "@" + sikuli_params[:hostname], :timeout => 60
      end
      exp.expect /%|#|$/
      sleep(1)
    
      # Unpack the test case
      # Run the sikuli command and look for results
      exp.send "cd " + sikuli_params[:working_dir] + "\r"
      exp.expect /%|#|$/
      sleep(1)
      exp.send "unzip " + result.test_case.uploads.first.upload.original_filename + "\r"
      exp.expect /%|#|$/
      sleep(1)
      exp.send("export DISPLAY=:0 \r")
      exp.expect /%|#|$/
      sleep(1)
      exp.send sikuli_params[:application_path] + ' -r ' + sikuli_params[:working_dir] + result.test_case.uploads.first.upload.original_filename.chomp('.zip') + " -s \r"
      exp.expect "Sikuli vision engine loaded"

    
      # WAit X minutes for this to pass. X defined in settings
      # We do this with a loop and keep trying
      minutes_elapsed = 0
      sikuli_finished = false
      while sikuli_finished == false
        # Note, we require users add print("Test complete")
        # Reason is that app exits with 255, so need a text marker
        match = exp.expect("Test complete", recoverable = true)
        # If no match is found after timeout we receive nil
        if match == nil
          LOGGER.info "Sikuli task not finished. Incrementing minute counter."
          minutes_elapsed += 1
          if minutes_elapsed >= sikuli_params[:max_run_time]
            LOGGER.warn "Timeout exceeded. Killing jMeter process."
            # Kill the process
            exp.send("\x3")
            sikuli_finished = true
            result.result = "Failed"
            result.note = "Sikuli time out. Run time exceeded #{sikuli_params[:max_run_time]} minutes.\n\n" + exp.all_output
            result.bugs = ""
            result.executed_at = Time.now
            result.save
          end
        else
          exp.expect /%|#|$/
          sikuli_finished = true
        end
      end
      sleep(1)
      
      # Remove the test plan zip
      exp.send "rm " + result.test_case.uploads.first.upload.original_filename + "\r"
      exp.expect /%|#|$/

      # Remove the unzipped test plan
      exp.send "rm -rf " + result.test_case.uploads.first.upload.original_filename.chomp!('.zip') + "\r"
      exp.expect /%|#|$/

      if result.result == nil
        result.result = "Passed"
        result.note = exp.all_output
        result.bugs = ""
        result.executed_at = Time.now
        return_value = result.save
      end
      
      exp.discard
      
    # If there is no test case. Mark as blocked and add explanation.
    else
      result.result = "Blocked"
      result.note = "Sikuli test case blocked. The test case does not have an attachment."
      result.bugs = ""
      result.executed_at = Time.now
      return_value = result.save
    end
  end
  
  private 
  
  # Analyze the downloaded file attachments
  def self.analyze_results(result)
    # Assume no failures. Mark a failure if one of the samples is marked as success = false
    failed = false

    result.uploads.each do |upload|
      # We analyze all files, but jmeter.log
      unless upload.upload_file_name == 'jmeter.log'
        # Open file for analysis
        f = File.open(upload.upload.path)
        doc = Nokogiri::XML(f)
        f.close

        # Do a search to find correspongin test_case_target for this file and grab content type
        test_case_target = result.test_case.test_case_targets.where("filename like ?", '%' + upload.upload_file_name).first
        # Set xpath string to use based on content type and en.yml
        xpath_string = (I18n.t :content_type_xpaths)[test_case_target.content]

        # Parse the xml file in to large array of samples (samples represetned by dictionary)
        samples = []
        doc.xpath(xpath_string).each do |element|
          sample = {}
          sample[:label] = element.attr("lb")
          sample[:time] = element.attr("t").to_i
          sample[:thread] = element.attr("tn")
          sample[:success] = element.attr("s")
          sample[:thread_name] = element.attr("tn")
          if sample[:success] == 'false'
            failed = true
          end
          samples << sample
        end

        # Build results array with per thread data
        results = {}
        samples.each do |sample|
          # If there are stats for this thread
          if results[sample[:thread_name]]
            # Check if ther are stats for this page in the thread
            # If yes, add values
            if results[sample[:thread_name]][sample[:label]]
              results[sample[:thread_name]][sample[:label]][:times] << sample[:time]
            # Otherwise add section for this page in this thread
            else
              results[sample[:thread_name]][sample[:label]] = {:times => [sample[:time]]}
            end
          # Otherwise, Create hash for the thread and then add page
          else
            results[sample[:thread_name]] = {}
            results[sample[:thread_name]][sample[:label]] = {:times => [sample[:time]]}
          end
        end
        
        # Strip min and max values for each page time in each thread
        results.each do |key, thread|
          thread.each do |key, page|
            if page[:times].count > 5
              # Remove the maximum value            
              page[:times].delete_at( page[:times].index( page[:times].max) )
              # Remove the minimum value
              page[:times].delete_at( page[:times].index( page[:times].min) )
            end
            # Calculate the total
            page[:total_time] = 0 
            page[:times].each { |a| page[:total_time]+=a } 
            # Find number of samples
            page[:num_samples] = page[:times].length
          end
        end

        # Get values per page load
        page_results = {}
        results.each do |key, thread|
          # puts thread
          thread.each do |key2, sample|
            if page_results[key2]
              page_results[key2][:total_time] += sample[:total_time]
              page_results[key2][:num_samples] += sample[:num_samples]
              page_results[key2][:times].concat(sample[:times])
            # Otherwise add section for this page in this thread
            else
              page_results[key2] = {:total_time => sample[:total_time], :num_samples => sample[:num_samples], :times => sample[:times]}
            end
          end
        end

        # Display statistics per page view
        page_results.each do |key, page|
          stats = calculate_statistics(page)
          ResultStatistic.create(:result_id => result.id, :test_case_target_id => test_case_target.id, :mean => stats[:mean], :standard_deviation => stats[:sd], :n => page[:num_samples], :statistic_type => 2, :name => key)
        end

        # Gathervalues for Total Results
        total_results = {:total_time => 0, :num_samples => 0, :times => []}
        page_results.each do |key, page|
          total_results[:total_time] += page[:total_time]
          total_results[:num_samples] += page[:num_samples]
          total_results[:times].concat(page[:times])
        end

        # Display total results
        mean = total_results[:total_time] / total_results[:num_samples]
        stats = calculate_statistics(total_results)
        ResultStatistic.create(:result_id => result.id, :test_case_target_id => test_case_target.id, :mean => stats[:mean], :standard_deviation => stats[:sd], :n => total_results[:num_samples], :statistic_type => 1, :name => 'All Requests')
      end
    end
    
    # Mark the result as failed if one more more requests failed
    if failed == true
      result.result = "Failed"
      result.note = "At least one sample had success marked as false."
      result.bugs = ""
      result.executed_at = Time.now
      return_value = result.save
    end
  end
  
  # downloada file via scp and copy to result item
  def self.copy_file_to_result(result, host, filename)
    # Figure out if filename is relative to working dir or absolute
    # If it is not absolute, adding in working dir value to beginning for use with SCP
    unless filename.match /^\//
      filename = host[:working_dir] + filename
    end
    
    # Copy the file using SCP to the rails tmp/ folder
    # Use the password login
    if host[:certificate] == nil or host[:certificate] == "" or host[:certificate] == "none"
      LOGGER.info "Using password based login."
      exp_down = ExpectrCustom.new "scp " + host[:username] + "@" + host[:hostname] + ":" + filename + " " + Rails.root.to_s + "/tmp/", :timeout => 60
      exp_down.expect /[Pp]assword\:/
      sleep(1)
      exp_down.send host[:password] + "\r"
    # Use certificate login
    else
      LOGGER.info "Using certificate based login."
      exp_down = ExpectrCustom.new "scp -i " + host[:certificate] + ' ' +  host[:username] + "@" + host[:hostname] + ":" + filename + " " + Rails.root.to_s + "/tmp/", :timeout => 60   
    end
    
    begin  
      exp_down.expect  "100%"
    rescue PTY::ChildExited => e  
      LOGGER.info "SCP finished before captured. This is normal for small files."  
    end
    sleep(1)
    output_down= exp_down.discard
    
    # save the file from the tmp folder to an attachment
    newupload = result.uploads.build
    # Note we use File.basename to strip away full path and just get filename as that is what is in tmp/
    newupload.upload = File.open(Rails.root.to_s + '/tmp/' + File.basename(filename) )
    newupload.save!
    
    # puts "DELETING"
    # Delete the file from tmp/
    File.delete(Rails.root.to_s + '/tmp/' + File.basename(filename) )
    # puts "DELETED"
  end
  
  # Upload a file using scp
  def self.scp_file(host, upload)
    # Upload the jmeter test plan
    if host[:certificate] == nil or host[:certificate] == "" or host[:certificate] == "none"
      exp_up = ExpectrCustom.new "scp " + upload.upload.path + " " + host[:username] + "@" + host[:hostname] + ":" + host[:working_dir] + upload.upload.original_filename, :timeout => 60
      exp_up.expect /[Pp]assword\:/
      sleep(1)
      exp_up.send host[:password] + "\r"
    else
      exp_up = ExpectrCustom.new "scp -i " + host[:certificate] + ' ' + upload.upload.path + " " + host[:username] + "@" + host[:hostname] + ":" + host[:working_dir] + upload.upload.original_filename, :timeout => 60
    end
    
    begin  
      exp_up.expect  "100%"
    rescue PTY::ChildExited => e  
      LOGGER.info "SCP finished before captured. This is normal for small files."  
    end

    sleep(1)
    output_up = exp_up.discard
  end
  
  # Returns a list of the jmeter host parameters in a dictionary
  def self.get_jmeter_parameters()
    jmeter_params = {}
    jmeter_params[:username] = Setting.value('jMeter User')
    jmeter_params[:hostname] = Setting.value('jMeter Host')
    jmeter_params[:password] = Setting.value('jMeter Password')
    jmeter_params[:certificate] = Setting.value('jMeter SSH Certificate')
    jmeter_params[:working_dir] = Setting.value('jMeter Working Directory')
    jmeter_params[:application_path] = Setting.value('jMeter Application Path')
    jmeter_params[:max_run_time] = Setting.value('jMeter Max Execution Time').to_i
    
    # Verify working dir ends with /
    ends_with_slash = /\/$/
    unless jmeter_params[:working_dir].match ends_with_slash
      jmeter_params[:working_dir] = jmeter_params[:working_dir] + '/'
    end
    
    jmeter_params
  end
  
  def self.get_sikuli_parameters()
    sikuli_params = {}
    sikuli_params[:username] = Setting.value('Sikuli User')
    sikuli_params[:hostname] = Setting.value('Sikuli Host')
    sikuli_params[:password] = Setting.value('Sikuli Password')
    sikuli_params[:certificate] = Setting.value('Sikuli SSH Certificate')
    sikuli_params[:working_dir] = Setting.value('Sikuli Working Directory')
    sikuli_params[:application_path] = Setting.value('Sikuli Application Path')
    sikuli_params[:max_run_time] = Setting.value('Sikuli Max Execution Time').to_i
    
    # Verify working dir ends with /
    ends_with_slash = /\/$/
    unless sikuli_params[:working_dir].match ends_with_slash
      sikuli_params[:working_dir] = sikuli_params[:working_dir] + '/'
    end
    
    sikuli_params
  end
  
  # Takes a result dictionary and returns a dictionary of statistics
  # Return {:mean => , :sd => } where n is num samples and sd is standard dev
  def self.calculate_statistics (result)
    mean = result[:total_time] / result[:num_samples]

    if result[:num_samples] > 1
      sum_of_squared_differences = 0

      result[:times].each do |time|
        sum_of_squared_differences += (time - mean)**2
      end

      standard_deviation = Math.sqrt(sum_of_squared_differences / (result[:num_samples] - 1))
    else
      standard_deviation = 0
    end
    
    {:mean => mean, :sd => standard_deviation}
  end
end
