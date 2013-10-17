module ReportsHelper
  REPORT_TYPES = ["System Status", "Release Current State", "Release Current State - By User", "Release Progress - Daily", "Compare Release Results", "Test Cases without Steps", "Open Tasks", "Release Bug Report", "Compare Release Results - Detailed" ]
  
  # returns a s list of users for a select item
  # def user_list()
  #  User.find(:all, :order => "last_name").collect {|u| [ u.last_name + ", " + u.first_name, u.id ]}
  # end
  
  # Returns a list of all open tasks for a user
  def list_open_tasks()
    Task.where("status != 127")  
  end
  
  
  # Takes a bug I and returns the url to the bug, based on common usage assumptions
  def generate_bug_link( bug_id )
    # For bugzilla, assume url is base URL plus show by bug ID
    if Setting.value("Ticket System") == 'Bugzilla'
      url = Setting.value('Ticket System Url') + 'show_bug.cgi?id=' + bug_id.to_s
    # For mantis, base url plus view id
    elsif Setting.value("Ticket System") == 'Mantis'
      url = Setting.value('Ticket System Url') + 'view.php?id=' + bug_id.to_s
    # For Jira, we strip the API part of url that starts with rest/api...
    elsif Setting.value("Ticket System") == 'Jira'
      url = Setting.value('Ticket System Url').split('rest/')[0] + 'browse/' + bug_id.to_s
    #If we're not sure what it is, return a blank url
    elsif Setting.value("Ticket System") == 'Redmine'
      url = Setting.value('Ticket System Url') + 'issues/' + bug_id.to_s
    else
      url = ""
    end
    
    #Return the URL
    url
  end
  
  
  # Provides an array of total cases. One value for each day in the range
  # start_time to end_time. Total value is always the same.
  # Uses product_id and version_id to select applicable assignments and their results
  def release_progress_daily_total_cases_series(product_id, version_id, start_time, end_time)
    number_of_cases = Result.where(:assignment_id => Assignment.where(:product_id => product_id, :version_id => version_id) ).count()
    
    output = []
    (start_time..end_time).map do |date|
      output.push [date.to_time.to_i * 1000, number_of_cases]
    end
    output.to_s
  end
  
  # Provides an array of the cumulative number of test cases passed/ailed/blocked on a given day
  # Does passed/failed/blocked based on calue of result
  # Array provides one item per day from start_time to end_time
  # Uses product_id and version_id to select applicable assignments and their results
  def release_progress_daily_series(product_id, version_id, result, start_time, end_time)
    # Get a count of number of executed items for a given day.
    # Only count results with the desired result
    results_by_day = Result.select("date(results.executed_at), count(id) as total_executed").where(:assignment_id => Assignment.where(:product_id => product_id, :version_id => version_id).collect(&:id) ).
      where(:result => result, :executed_at => start_time.beginning_of_day..end_time.end_of_day).
      group("date(results.executed_at)")

    # Count the cumulative total for all items and place in to an array that is returned
    cumulative_total = 0
    output = []
    (start_time..end_time).map do |date|
      result = results_by_day.detect { |result| result.date.to_date == date }      
      if result then cumulative_total += result.total_executed.to_i end
      output.push [date.to_time.to_i * 1000, cumulative_total]
    end
    output
  end
  
  # Takes a product, version and result type and returns the number of cases that match
  def release_result(product_id, version_id, result)
    Result.where(:assignment_id =>  Assignment.where(:product_id => product_id, :version_id => version_id).
      collect(&:id) ).
      where(:result => result).count()
  end

  # Takes a product and version and returns all matching results
  def release_results(product_id, version_id)
    Result.where(:assignment_id =>  Assignment.where(:product_id => product_id, :version_id => version_id).collect(&:id) )
  end

  # Takes a product_id and version_id and returns the number of cases for that release
  def release_case_count(product_id, version_id)
    Result.where(:assignment_id =>  Assignment.where(:product_id => product_id, :version_id => version_id)).count()
  end

  def test_cases_without_steps_list(product_id)
    # Return a list of all test cases with product IDs.
    # Note that a product id is optional.
    if product_id == nil
      TestCase.joins("LEFT OUTER JOIN steps ON steps.test_case_id = test_cases.id").where("steps.id is NULL")
    else
      TestCase.where(:product_id => product_id).joins("LEFT OUTER JOIN steps ON steps.test_case_id = test_cases.id").where("steps.id is NULL")
    end
  end
  
  
  # Takes a user_id, product_id, and version id
  # Finds all cases assigned to user as a task for that product and release
  # Returns dictionary with passed, failed, blocked, not run count
  def user_bug_count(user_id, product_id, version_id)
    # Prepare the hash that will be returned from the function
    result = {}

    # Find all of the results related to a user, for a specific release (product and version)
    # Note, 4 queries run in this function, but usually this function is called several times by a report
    # Will need to optimize at some point    
    result["passed"] = Result.where(:result => "Passed" ).joins(:assignment).where("assignments.product_id = ? and assignments.version_id = ?", product_id, version_id).joins(:task).where("tasks.user_id = ?", user_id).count
    result["failed"] = Result.where(:result => "Failed" ).joins(:assignment).where("assignments.product_id = ? and assignments.version_id = ?", product_id, version_id).joins(:task).where("tasks.user_id = ?", user_id).count
    result["blocked"] = Result.where(:result => "Blocked" ).joins(:assignment).where("assignments.product_id = ? and assignments.version_id = ?", product_id, version_id).joins(:task).where("tasks.user_id = ?", user_id).count
    result["not_run"] = Result.where(:result => nil ).joins(:assignment).where("assignments.product_id = ? and assignments.version_id = ?", product_id, version_id).joins(:task).where("tasks.user_id = ?", user_id).count
    
    return result
  end
  
  # Takes a list of Results
  # Returns the status for all bugs
  def list_bug_status(results)
    bug_ids = []
    bug_ids_with_results = {}
    
    # Build a list of bug ids to query the ticket system
    results.each do |result|
      # first make sure not nil
      if result.bugs != nil
        # then split bugs as they are split by commas
        bugs = result.bugs.split(',')
        # it is possible that hte list was blank, so we check array isn't empty
        unless bugs == []
          bugs.each do |bug|
            # add all values to list
            bug_ids << bug
            
            # We make a separate dictionary of all bugs. the dictionary is a list of bug ids with the reslated results
            # Ex. { :bug_id_1 => [result_id_1, result_id3], :bug_id_2 => [result_id_1, result_id_2] }
            if bug_ids_with_results[bug] == nil
              bug_ids_with_results[bug] = [result.id]
            else
              bug_ids_with_results[bug] << result.id
            end
          end    
        end
      end
    end  
    # Remove duplicate values from IDs
    bug_ids = bug_ids.uniq

    # If a ticketing system is used, find status of all bugs
    if Setting.value('Ticket System') != 'none'
      # If ticket system is set, check that all bugs exist
      # need to send bug status an array of IDs so we split the comma separated list
      bug_results = Ticket.bug_status( bug_ids )
    else
      bug_results = {}
      bug_ids.each do |bug|
        bug_results[bug] = { :name => 'Not Found', :status => 'Not Found' }
      end
    end

    # Now that we have the list of bugs with the status and names
    # We add the array of associated result IDs to the bugs. We use the dictionary
    # created earlier in this function. 
    bug_results.each_key do |key|
      # Error key won't exist
      bug_results[key][:result_ids] = bug_ids_with_results[key]
    end

    return bug_results
  end
  
  def test_cases_in_versions(version1, version2)
    results1 = Result.where(:assignment_id => Assignment.where(:version_id => version1)).joins(:assignment).joins(:test_plan)
    results2 = Result.where(:assignment_id => Assignment.where(:version_id => version2)).joins(:assignment).joins(:test_plan)

    results = []

    results1.each do |result|
      results << {:tp_id => result.assignment.test_plan.id,
                  :tp_name => result.assignment.test_plan.name,
                  :tp_version => result.assignment.test_plan.version,
                  :tc_id => result.test_case_id,
                  :name => result.test_case.name,
                  :v1_result => result.result, 
                  :v1_comment => result.note,
                  :tc_version => result.test_case.version}
    end

    results2.each do |result|
      found = false
      results.each do |old_result|
        if result.assignment.test_plan.id == old_result[:tp_id] and result.test_case_id == old_result[:tc_id]
          found = true
          old_result[:v2_result] = result.result
          old_result[:v2_comment] = result.note
        end
      end
      
      unless found
        results << {:tp_id => result.assignment.test_plan.id,
                    :tp_name => result.assignment.test_plan.name,
                    :tp_version => result.assignment.test_plan.version,
                    :tc_id => result.test_case_id,
                    :name => result.test_case.name,
                    :v2_result => result.result, 
                    :v2_comment => result.note,
                    :tc_version => result.test_case.version}
      end
    end
    results
  end
end
