class CreateTestCaseTargets < ActiveRecord::Migration
  def self.up
    create_table :test_case_targets do |t|
      t.string :filename
      t.integer :test_case_id
      t.integer :content, :limit => 2

      t.timestamps
    end
  end

  def self.down
    drop_table :test_case_targets
  end
end
