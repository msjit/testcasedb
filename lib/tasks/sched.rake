require 'thread'

namespace :sched do
  desc "Start the scheduler"
  task :start => :environment do
    # Record the start time
    START_TIME = Time.now

    # Configure the global logger
    LOGGER = Logger.new('log/scheduler.log', 10, 1048576)
    
    # Generate the global mutex for the threads
    SEMAPHORE = Mutex.new

    # Only run the scheduler if attachment execution is configured.
    if Setting.value('Allow attachment execution') == true
      # Clear out schedule runs. We ignore everything older than 1 day
      # We use delete instead of destroy as it is quicker. Less queries, doesn't load data
      ScheduleRun.delete_all(["start_time < ?", 1.day.ago])
    
      LOGGER.info "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')} INFO: Scheduler process started at #{START_TIME}"
    
      # Find the active devices
      devices = find_devices
    
      # Collection of all threads
      threads = []
    
      # We start off serially searching for tasks on devices
      devices.each do |device|
        # Only investigate the device if there is no lockfile
        if lockfile_exists(device.id) == false
          # Search for scheduled test plans
          scheduled_test_plans = find_scheduled_test_plans(device)
      
          # If there are tests to run, spawn a thread for the queue
          if scheduled_test_plans.count > 0
            threads << Thread.new do
              # Run the device thread task
              # This includes all locking, locking and test running
              device_thread(device, scheduled_test_plans)
            end
          else
            SEMAPHORE.synchronize do
              LOGGER.info "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')} INFO: No scheduled tasks for #{device.name}"
            end
          end
        
          # Record the time that this was executed.
          # This is required by find test plans to know when was last successfull check
          SEMAPHORE.synchronize do
            ScheduleRun.create(:device_id => device.id, :start_time => START_TIME)
          end
        else
          SEMAPHORE.synchronize do
            LOGGER.info "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')} INFO: Skipping device #{device.name}. Lockfile exists."
          end
        end
      end
    
      # Wait for all threads to finish before exiting
      threads.each { |t| t.join }
      
    # Attachment execution is not allowed.
    else
      LOGGER.warn "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')} WARN:Scheduler is disabled, because the allow attachment execution setting is disabled."
    end
    
  end
end

# Create the assignment based on version and test plan
# return the assignment
def create_assignment(test_plan, version, schedule)
  assignment = Assignment.create(:product_id => test_plan.product_id, :version_id => version.id, :test_plan_id => test_plan.id, :notes => 'Created by automation harness', :schedule_id => schedule.id)
  
  # For each test case in the test plan, we must make a result_case
  # related to the testplan
  assignment.test_plan.test_cases.each do |testCase|
    assignment.results.create(:test_case_id => testCase.id)
  end

  LOGGER.debug "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')} DEBUG: Assignment with ID: #{assignment.id} created"
  
  assignment
end

# Create a lockfile
# One argument, the ID of the device item
# Returns true if lockfile is created 
def create_lockfile(device_id)
  # This process creates a lockfile
  lock_file_location = Rails.root.to_s + '/tmp/device' + device_id.to_s + '.lock'
  
  # assume file not created
  created_lockfile = false

  SEMAPHORE.synchronize do  
    # If file doesn't exist, create it
    if !FileTest.exists?(lock_file_location)

      begin
        file = File.open(lock_file_location,'w')
        file.close
        created_lockfile = true
        LOGGER.info "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')} INFO: Lock file created for device with ID #{device_id}"
      rescue
        LOGGER.error "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')} ERR: Error creating lock file for device with ID #{device_id}"
      end
    else
      LOGGER.info "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')} INFO: Lock file for device with ID #{device_id} already exists. Will not run scheduled tasks"
    end
  end
  
  created_lockfile
end

# Delete a lockfile
# One argument, the ID of the device item
# Returns true if lockfile is deleted 
def delete_lockfile(device_id)
  # This process deletes an existing lockfile
  lock_file_location = Rails.root.to_s + '/tmp/device' + device_id.to_s + '.lock'
  
  # assume file not deleted
  deleted_lockfile = false

  SEMAPHORE.synchronize do  
    # If file exists, delete it
    if FileTest.exists?(lock_file_location)
      begin
        File.delete(lock_file_location)
        deleted_lockfile = true
        LOGGER.info "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')} INFO: Lock file deleted for device with ID #{device_id}"
      rescue
        LOGGER.error "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')} ERR: Error deleting lock file for device with ID #{device_id}"
      end
    else
      LOGGER.info "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')} INFO: Lock file for device with ID #{device_id} does not exist exists. Could not delete."
    end
  end
    
  deleted_lockfile
end

# Controll function for each thread
# When a device is found with scheduled items to run
# a thread is spawn to run this function which controls the process
# Inputs are the device and the schedule item with test plans
def device_thread(device, schedules)
  # Task continues if lock created successfully
  if create_lockfile(device.id)
    SEMAPHORE.synchronize do
      LOGGER.info "There are test plans to run for #{device.name}"
    end

    schedules.each do |schedule|
      assignment = nil
      SEMAPHORE.synchronize do
        version = generate_version(schedule.test_plan)
        assignment = create_assignment(schedule.test_plan, version, schedule)
      end
      
      # This begin/rescue is important. A lot can go wrong with test cases
      # We must capture this so we can still clean up the lock file
      begin
        execute_test_cases(assignment)
        # Now that the assignment is complete, we mail the results
        SEMAPHORE.synchronize do
          AutomationMailer.send_results(assignment, schedule).deliver
        end
      rescue
         LOGGER.error "There was a failure running the test cases."
      end
    end

    # Delete lock as task is complete
    delete_lockfile(device.id)
  end

  LOGGER.debug "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')} DEBUG: Exiting thread for device #{device.name}"
end


# take the assignment and execute all of the test cases
def execute_test_cases(assignment)
  # Find all results related to test case
  # Test cases are ordered according to test plan order
  results = nil
  SEMAPHORE.synchronize do
    # results = Result.where(:assignment_id => assignment.id).
    #   joins('left join assignments on (results.assignment_id = assignments.id)').
    #   joins('left join plan_cases on (plan_cases.test_case_id = results.test_case_id AND plan_cases.test_plan_id = assignments.test_plan_id)').
    #   order('case_order')  
    results = Result.where(:assignment_id => assignment.id).order('id')
  end
  
  results.each do |result|
    # The result from the large query is not editable
    # We create an editable result item
    editable_result = Result.find(result.id)
    SEMAPHORE.synchronize do
      LOGGER.info "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')} INFO: Executing test case #{result.test_case.name}"
    end 

    # If this is a jMeter test case, use the jmeter code
    if result.test_case.test_type_id == TestType.where(:name => 'jMeter').first.id
      Schedule.jmeter(editable_result)
    # Otherwise run standard automation
    elsif result.test_case.test_type_id == TestType.where(:name => 'Sikuli').first.id
      Schedule.sikuli(editable_result)
    else
      # If there is a script attached, try to run it    
      if result.test_case.uploads.first != nil
        # Anything can happen that will cause scripts to fail
        # We capture and mark as failed
        begin
          # Run script and save output to note
          output = `#{result.test_case.uploads.first.upload.path} 2>&1`
          editable_result.note = output
          # If the script exit status is 0 it passes
          if $?.exitstatus == 0
            editable_result.result = "Passed"
          # Otherwise it is considered to be a failure
          else
            editable_result.result = "Failed"
          end
        # Script unable to run
        rescue
          editable_result.result = "Failed"
          editable_result.note = "Error occurred running script. TestCaseDB caught error."
        end
      # No script attached to test case. It is marked as blocked
      else
        editable_result.result = "Blocked"
        editable_result.note = "No scripts attached to test case."
      end
      SEMAPHORE.synchronize do
        editable_result.save
      end
    end
  end
end


# Returns an array of active devices
def find_devices
  devices = Device.where(:active => true)
  LOGGER.info "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')} INFO: #{devices.count} active device(s) found"
  devices
end

# Take a device and return a list of scheduled test plans
def find_scheduled_test_plans(device)
  # First we must calculate the search time.
  # All start times for TCDB are calculated on 5 minute intervals, so we simply calculate the previous
  search_time = START_TIME - (START_TIME.min % 5).minutes - START_TIME.sec
  
  # We also search Schedule Run for a previous entry.
  previous_run = ScheduleRun.where(:device_id => device.id).order('start_time').last
  
  # IF there are no previous runs to use, we assume search for the current time only
  if previous_run == nil
    LOGGER.debug "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')} DEBUG: No previous Schedule run entries found for device #{device.name}"
    # We need to check the day of the week for the query. We use the wday field. 0 = Sunday, 6 = Saturday
    if START_TIME.wday == 0
      scheduled_plans = Schedule.where(:device_id => device.id, :start_time => search_time, :sunday => true)
    elsif START_TIME.wday == 1
      scheduled_plans = Schedule.where(:device_id => device.id, :start_time => search_time, :monday => true)
    elsif START_TIME.wday == 2
      scheduled_plans = Schedule.where(:device_id => device.id, :start_time => search_time, :tuesday => true)
    elsif START_TIME.wday == 3
      scheduled_plans = Schedule.where(:device_id => device.id, :start_time => search_time, :wednesday => true)
    elsif START_TIME.wday == 4
      scheduled_plans = Schedule.where(:device_id => device.id, :start_time => search_time, :thursday => true)
    elsif START_TIME.wday == 5
      scheduled_plans = Schedule.where(:device_id => device.id, :start_time => search_time, :friday => true)
    elsif START_TIME.wday == 6
      scheduled_plans = Schedule.where(:device_id => device.id, :start_time => search_time, :saturday => true)
    end
  
  # Since there is a previous run, we search between it and now.
  # This is done because it is possible that the previous run went over multiple time periods
  # We make sure all missed items are run now.  
  else
    
    # If the start time was from yesterday, our search should span multiple days
    if previous_run.start_time <  Date.today.midnight
      LOGGER.debug "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')} DEBUG: Previous schedule run entry found for previous day for device #{device.name}"
      # We need to check the day of the week for the query. We use the wday field. 0 = Sunday, 6 = Saturday
      # We need to check yesterday to midnight and today from midnight to now
      # Why is each day done in two sections... the answer is to simplify the ordering
      # As one query, ordering is complicated because the day on its own does not mean that it was accepted for yesterday
      if START_TIME.wday == 0
        previous_day_plans = Schedule.where(["device_id = ? AND start_time > ? AND saturday = true", device.id, previous_run.start_time] ).order('start_time')
        todays_plans = Schedule.where(["device_id = ? AND start_time <= ? AND sunday = true", device.id, search_time] ).order('start_time')
        scheduled_plans = previous_day_plans + todays_plans
      elsif START_TIME.wday == 1
        previous_day_plans = Schedule.where(["device_id = ? AND start_time > ? AND sunday = true", device.id, previous_run.start_time] ).order('start_time')
        todays_plans = Schedule.where(["device_id = ? AND start_time <= ? AND monday = true", device.id, search_time] ).order('start_time')
        scheduled_plans = previous_day_plans + todays_plans
      elsif START_TIME.wday == 2
        previous_day_plans = Schedule.where(["device_id = ? AND start_time > ? AND monday = true", device.id, previous_run.start_time] ).order('start_time')
        todays_plans = Schedule.where(["device_id = ? AND start_time <= ? AND tuesday = true", device.id, search_time] ).order('start_time')
        scheduled_plans = previous_day_plans + todays_plans
      elsif START_TIME.wday == 3
        previous_day_plans = Schedule.where(["device_id = ? AND start_time > ? AND tuesday = true", device.id, previous_run.start_time] ).order('start_time')
        todays_plans = Schedule.where(["device_id = ? AND start_time <= ? AND wednesday = true", device.id, search_time] ).order('start_time')
        scheduled_plans = previous_day_plans + todays_plans
      elsif START_TIME.wday == 4
        previous_day_plans = Schedule.where(["device_id = ? AND start_time > ? AND wednesday = true", device.id, previous_run.start_time] ).order('start_time')
        todays_plans = Schedule.where(["device_id = ? AND start_time <= ? AND thursday = true", device.id, search_time] ).order('start_time')
        scheduled_plans = previous_day_plans + todays_plans
      elsif START_TIME.wday == 5
        previous_day_plans = Schedule.where(["device_id = ? AND start_time > ? AND thursday = true", device.id, previous_run.start_time] ).order('start_time')
        todays_plans = Schedule.where(["device_id = ? AND start_time <= ? AND friday = true", device.id, search_time] ).order('start_time')
        scheduled_plans = previous_day_plans + todays_plans
      elsif START_TIME.wday == 6
        previous_day_plans = Schedule.where(["device_id = ? AND start_time > ? AND friday = true", device.id, previous_run.start_time] ).order('start_time')
        todays_plans = Schedule.where(["device_id = ? AND start_time <= ? AND saturday = true", device.id, search_time] ).order('start_time')
        scheduled_plans = previous_day_plans + todays_plans
      end
      
    # Otherwise, our search only checks the current day.
    else
      LOGGER.debug "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')} DEBUG: Previous schedule run entry found for device #{device.name}. Does not span days."
      # Since this is one day time span. check is easier
      # We simply check today is selected, and that time is between accepted times.
      # Notice that search is ordered by start time
      if START_TIME.wday == 0
        scheduled_plans = Schedule.where(["device_id = ? AND start_time > ? AND start_time <= ? AND sunday = true", device.id, previous_run.start_time, search_time] ).order("start_time")
      elsif START_TIME.wday == 1
        scheduled_plans = Schedule.where(["device_id = ? AND start_time > ? AND start_time <= ? AND monday = true", device.id, previous_run.start_time, search_time] ).order("start_time")
      elsif START_TIME.wday == 2
        scheduled_plans = Schedule.where(["device_id = ? AND start_time > ? AND start_time <= ? AND tuesday = true", device.id, previous_run.start_time, search_time] ).order("start_time")
      elsif START_TIME.wday == 3
        scheduled_plans = Schedule.where(["device_id = ? AND start_time > ? AND start_time <= ? AND wednesday = true", device.id, previous_run.start_time, search_time] ).order("start_time")
      elsif START_TIME.wday == 4
        scheduled_plans = Schedule.where(["device_id = ? AND start_time > ? AND start_time <= ? AND thursday = true", device.id, previous_run.start_time, search_time] ).order("start_time")
      elsif START_TIME.wday == 5
        scheduled_plans = Schedule.where(["device_id = ? AND start_time > ? AND start_time <= ? AND friday = true", device.id, previous_run.start_time, search_time] ).order("start_time")
      elsif START_TIME.wday == 6
        scheduled_plans = Schedule.where(["device_id = ? AND start_time > ? AND start_time <= ? AND saturday = true", device.id, previous_run.start_time, search_time] ).order("start_time")
      end
      
    end
    
  end    
  scheduled_plans
end

# Take a test plan and return a version
# If version exists, return, otherwise create
# return the version object
def generate_version(test_plan)
  # find the time at 5 minute interval
  search_time = START_TIME - (START_TIME.min % 5).minutes - START_TIME.sec
  # build version name using the time
  version_name = 'automation' + search_time.strftime('%Y_%m_%d-%H_%M')

  # Do a query for the version
  version = Version.where(:version => version_name, :product_id => test_plan.product_id).first
  
  # If verrsion doesn't exist, create it
  if  version == nil
    version = Version.create(:version => version_name, :product_id => test_plan.product_id, :description => 'Generated by automation tool.')
    LOGGER.info "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')} INFO: Version created (ID: #{version.id})"
  else
    LOGGER.info "#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')} INFO: Version exists (ID: #{version.id})"
  end
  
  version  
end


# Check if a lockfile exissts
# One argument, the ID of the device item
# Returns true if lockfile exists
def lockfile_exists(device_id)
  # This process checks if a lockfile exists
  lock_file_location = Rails.root.to_s + '/tmp/device' + device_id.to_s + '.lock'
  
  # assume file not created
  lockfile_exists = false
  
  # If file doesn't exist, create it
  if FileTest.exists?(lock_file_location)
    lockfile_exists = true
  end
  
  lockfile_exists
end