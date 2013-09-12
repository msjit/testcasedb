class CreateResultStatistics < ActiveRecord::Migration
  def self.up
    create_table :result_statistics do |t|
      t.integer :result_id
      t.integer :test_case_target_id
      t.integer :mean
      t.integer :standard_deviation
      t.integer :n
      t.integer :statistic_type, :limit => 2
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :result_statistics
  end
end
