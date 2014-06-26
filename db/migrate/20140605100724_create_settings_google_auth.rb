class CreateSettingsGoogleAuth < ActiveRecord::Migration
  def up
    Setting.find_or_create_by_name(:name => 'Google Auth enabled', :value => 'Disabled', :description => 'Enable Google Auth.')
    Setting.find_or_create_by_name(:name => 'Google Auth Client ID', :value => '')
    Setting.find_or_create_by_name(:name => 'Google Auth Secret', :value => '', :description => 'Google Auth Secret')
  end

  def down
    Setting.find_by_name('Google Auth enabled').destroy
    Setting.find_by_name('Google Auth Client ID').destroy
    Setting.find_by_name('Google Auth Secret').destroy
  end
end
