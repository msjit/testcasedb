module SchedulesHelper
  def devices_list
    Device.where(:active => true).order('name').collect {|d| [ d.name, d.id ]}
  end
  
  def user_email_list
    User.find(:all, :order => 'last_name, first_name').collect {|u| [u.last_name + ', ' + u.first_name + ' <' + u.email + '>', u.id]}
  end
  
  # This is used by AutomationMailer to add notes if required
  def generate_result_notes(result)
    # Find the ID of the previous assignment for this schedule
    assignments = Assignment.where(:schedule_id => result.assignment.schedule_id).order('id').last(2)
    
    # Make sure there is a previous run.
    if assignments.count == 2
      last_assignment_id = Assignment.where(:schedule_id => result.assignment.schedule_id).order('id').last(2)[0].id
      # Now that we know the assignment. Find the matching result in the assignment
      previous_result = Result.where(:assignment_id => last_assignment_id, :test_case_id => result.test_case_id).first
      
      # Make sure the previous result exists
      if previous_result
        # Now grab the result statistics for the previous run
        last_statistics = ResultStatistic.where(:result_id => previous_result.id)
        
        # And scroll through and compare all statistics for differences.
        # If there are difference add to the message
        final_message = ""
        result.result_statistics.each do |stat|
          last_statistics.each do |old_stat|
            # Make sure we are comparing like statistics
            if stat.name == old_stat.name
              percent_diff = ((stat.mean.to_f - old_stat.mean.to_f) / stat.mean.to_f * 100.0)
              if percent_diff > 10
                final_message += "Warning: " + stat.name + " load time was off by #{percent_diff.round} percent from previous run.<br>"
              end
            end
          end
        end
        
        # Return the final message for display in the email.
        final_message
        
      # If not, return blank text
      else
        " "
      end
    # No previous run, so just return no text
    else
      " "
    end    
  end
end
