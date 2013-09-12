class AddSecondVersionIdToReports < ActiveRecord::Migration
  def change
    add_column :reports, :second_version_id, :integer
  end
end
