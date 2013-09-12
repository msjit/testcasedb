class AddTaskIdToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :task_id, :integer
  end

  def self.down
    remove_column :comments, :task_id
  end
end
