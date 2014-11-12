class CreateTestCases < ActiveRecord::Migration
  def self.up
    create_table :test_cases do |t|
      t.text :name
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :test_cases
  end
end
