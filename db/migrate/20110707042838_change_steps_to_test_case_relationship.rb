class ChangeStepsToTestCaseRelationship < ActiveRecord::Migration
  def self.up
    drop_table :steps_test_cases
	  add_column :steps, :test_case_id, :integer
  end

  def self.down
	  create_table :steps_test_cases, :id => false do |t|
      t.integer :step_id
      t.integer :test_case_id
    end
    remove_column :steps, :test_case_id
  end
end
