class HelpController < ApplicationController
  layout false
  def index
    if params[:page_path] == '/'
      render 'help/admin/index' 
    else
      # Split by slashes, remove inital blank and integer values
      target_url = params[:page_path].split('/')[1..-1].reject { |l| l =~ /\A\d+\z/ }
    
      target_url << 'index' if target_url.length <= 1
    
      render "help/#{target_url[0]}/#{target_url[1]}" rescue render "help/#{target_url[0]}/index"
    end
  end
end
