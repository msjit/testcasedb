class CreatePlanCases < ActiveRecord::Migration
  def self.up
    create_table :plan_cases do |t|
      t.integer :test_case_id
      t.integer :test_plan_id
      t.integer :order, :limit => 2

      t.timestamps
    end
  end

  def self.down
    drop_table :plan_cases
  end
end
