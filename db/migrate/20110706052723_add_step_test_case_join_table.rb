class AddStepTestCaseJoinTable < ActiveRecord::Migration
  def self.up
    create_table :steps_test_cases, :id => false do |t|
      t.integer :step_id
      t.integer :test_case_id
    end
  end

  def self.down
    drop_table :steps_test_cases
  end
end
