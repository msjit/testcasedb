class CreateHistories < ActiveRecord::Migration
  def self.up
    create_table :histories do |t|
      t.integer :user_id
      t.integer :action, :limit => 1
      t.integer :test_case_id
      t.integer :test_plan_id
      t.integer :result_case_id

      t.timestamps
    end
  end

  def self.down
    drop_table :histories
  end
end
