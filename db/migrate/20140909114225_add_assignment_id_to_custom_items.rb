class AddAssignmentIdToCustomItems < ActiveRecord::Migration
  def self.up
    add_column :custom_items, :assignment_id, :integer
  end

  def self.down
    remove_column :custom_items, :assignment_id
  end
end
