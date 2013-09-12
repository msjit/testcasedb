class AddTestCaseIdToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :test_plan_id, :integer
  end

  def self.down
    remove_column :comments, :test_plan_id
  end
end
