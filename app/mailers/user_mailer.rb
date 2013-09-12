class UserMailer < ActionMailer::Base
  default :from => "testcasedb@gmail.com"
  
  def task_assigned(task, url)
    @task = task
    @url = url
    mail(:to => "#{@task.user.first_name} #{@task.user.last_name} <#{@task.user.email}>", :subject => "A task has been assigned to you.")
  end
end
