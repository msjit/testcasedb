class HomeController < ApplicationController
  def index
    @histories = History.order("id DESC").limit(10).includes(:test_case).includes(:product).includes(:result).includes(:user)
    @tasks = Task.where(["user_id = :user_id AND status != 127", {:user_id => current_user.id}]).order("due_date").limit(10)
  end

end
