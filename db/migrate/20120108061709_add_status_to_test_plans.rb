class AddStatusToTestPlans < ActiveRecord::Migration
  def self.up
    add_column :test_plans, :status, :integer, :limit => 2
  end

  def self.down
    remove_column :test_plans, :status
  end
end
