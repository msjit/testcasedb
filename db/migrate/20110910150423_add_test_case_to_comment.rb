class AddTestCaseToComment < ActiveRecord::Migration
  def self.up
    add_column :comments, :test_case_id, :integer
  end

  def self.down
    remove_column :comments, :test_case_id
  end
end
