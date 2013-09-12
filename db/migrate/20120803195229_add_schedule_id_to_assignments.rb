class AddScheduleIdToAssignments < ActiveRecord::Migration
  def self.up
    add_column :assignments, :schedule_id, :integer
  end

  def self.down
    remove_column :assignments, :schedule_id
  end
end
