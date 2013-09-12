class AutomationMailer < ActionMailer::Base
  helper :schedules
  default :from => "testcasedb@gmail.com"
  
  def send_results(assignment, schedule)
    @assignment = assignment
    
    # @results = Result.where(:assignment_id => @assignment.id).
    #   joins('left join assignments on (results.assignment_id = assignments.id)').
    #   joins('left join plan_cases on (plan_cases.test_case_id = results.test_case_id AND plan_cases.test_plan_id = assignments.test_plan_id)').
    #   order('case_order')
    @results = Result.where(:assignment_id => @assignment.id).order('id')
    
    email_recipients =""
    schedule.users.each do |user|
      email_recipients = email_recipients + user.first_name + " " + user.last_name + " <" + user.email + ">,"
    end
    
    # mail(:to => "#{@task.user.first_name} #{@task.user.last_name} <#{@task.user.email}>", :subject => "A task has been assigned to you.")
    mail(:to => email_recipients, :subject => "Automation Results - #{@assignment.test_plan.name}")
  end
end