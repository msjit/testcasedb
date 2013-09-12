class AddVersionAndParentToTestCase < ActiveRecord::Migration
  def self.up
    add_column :test_cases, :version, :integer, :limit => 2, :default => 1
    add_column :test_cases, :parent_id, :integer
  end

  def self.down
    remove_column :test_cases, :version
    remove_column :test_cases, :parent_id
  end
end
