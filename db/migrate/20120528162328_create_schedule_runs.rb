class CreateScheduleRuns < ActiveRecord::Migration
  def self.up
    create_table :schedule_runs do |t|
      t.integer :device_id
      t.datetime :start_time

      t.timestamps
    end
  end

  def self.down
    drop_table :schedule_runs
  end
end
