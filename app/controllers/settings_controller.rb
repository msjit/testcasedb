class SettingsController < ApplicationController
  def index
    authorize! :read, Setting
    settings = Setting.all
    
    # @num_licensed_users = validate_license(Setting.where(:name => "License Key").first.value)
    @settings = { :general => [], :ticket => [], :jmeter => [], :results => [], :sikuli => []}
    
    tickets = /^Ticket/
    jmeters = /^jMeter/
    results = /^Require/
    sikulis = /^Sikuli/
    
    settings.each do |setting|
      if setting.name.match tickets
        @settings[:ticket] << setting
      elsif setting.name.match jmeters
        @settings[:jmeter] << setting
      elsif setting.name.match results
        @settings[:results] << setting
      elsif setting.name.match sikulis
        @settings[:sikuli] << setting
      else
        @settings[:general] << setting
      end
    end
    
  end

  def edit
    authorize! :update, Setting
    @setting = Setting.find(params[:id])
    
    if @setting.name == 'SystemID'
      redirect_to settings_url, :flash => { :warning => "Invalid Entry" }
    else
      render
    end
  end

  def update
    authorize! :update, Setting
    @setting = Setting.find(params[:id])
    
    Rails.logger.info "Updating setting - " + @setting.name
    if @setting.update_attributes(params[:setting])
      Rails.logger.info "Setting, " + @setting.name + ", saved."
      redirect_to settings_url, :notice  => "Successfully updated setting."
    else
      Rails.logger.warn "There was an error saving " + @setting.name
      render :action => 'edit', :flash => { :warning => "There was an issue saving this setting."}
    end
  end
end
