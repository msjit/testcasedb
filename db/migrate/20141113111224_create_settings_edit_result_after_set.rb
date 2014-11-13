class CreateSettingsEditResultsAfterSet < ActiveRecord::Migration
  def up
    Setting.find_or_create_by_name(:name => 'Allow Result Edit After Set', :value => 'Disabled', :description => 'Once a result has been set, editing the result is blocked if this is disabled.')
  end

  def down
    Setting.find_by_name('Allow Result Edit After Set').destroy
  end
end
