module TasksHelper
  def task_types 
      I18n.t(:task_types).map { |key, value| [ value, key ] } 
  end
  def task_status 
      I18n.t(:task_status).map { |key, value| [ value, key ] } 
  end
end
