class AdminController < ApplicationController
  def index
    authorize! :read, Admin
  end

end
