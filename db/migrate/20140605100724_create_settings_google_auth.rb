class CreateSettingsGoogleAuth < ActiveRecord::Migration
  def up
    Setting.find_or_create_by_name(:name => 'Google Auth enabled', :value => true, :description => 'Enable Google Auth.')
    Setting.find_or_create_by_name(:name => 'Google Auth Client ID', :value => '365073516956-44957ki7m1v145l9n6gs2sfrc34f05u4.apps.googleusercontent.com', :description => 'Google Auth Client ID.')
    Setting.find_or_create_by_name(:name => 'Google Auth Secret', :value => 'N2bHxPfTjMprcaxhW-jHr4MN', :description => 'Google Auth Secret')
  end

  def down
    Setting.find_by_name('Google Auth enabled').destroy
    Setting.find_by_name('Google Auth Client ID').destroy
    Setting.find_by_name('Google Auth Secret').destroy
  end
end
