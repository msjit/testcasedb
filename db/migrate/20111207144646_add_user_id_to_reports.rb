class AddUserIdToReports < ActiveRecord::Migration
  def self.up
    add_column :reports, :user_id, :integer
  end

  def self.down
    remove_column :reports, :user_id
  end
end
