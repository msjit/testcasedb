class AddUsersToTestPlans < ActiveRecord::Migration
  def self.up
    add_column :test_plans, :created_by_id, :integer
    add_column :test_plans, :modified_by_id, :integer
  end

  def self.down
    remove_column :test_plans, :created_by_id
    remove_column :test_plans, :modified_by_id
  end
end
