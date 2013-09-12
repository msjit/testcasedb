class AddTaskIdToHistories < ActiveRecord::Migration
  def self.up
    add_column :histories, :task_id, :integer
  end

  def self.down
    remove_column :histories, :task_id
  end
end
