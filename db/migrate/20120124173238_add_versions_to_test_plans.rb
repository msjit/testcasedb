class AddVersionsToTestPlans < ActiveRecord::Migration
  def self.up
    add_column :test_plans, :version, :integer, :limit => 2, :default => 1
    add_column :test_plans, :parent_id, :integer
    add_column :test_plans, :deprecated, :boolean, :default => 0
  end

  def self.down
    remove_column :test_plans, :version
    remove_column :test_plans, :parent_id
    remove_column :test_plans, :deprecated
  end
end
