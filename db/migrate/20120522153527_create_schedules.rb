class CreateSchedules < ActiveRecord::Migration
  def self.up
    create_table :schedules do |t|
      t.integer :device_id
      t.integer :product_id
      t.integer :test_plan_id
      t.boolean :monday
      t.boolean :tuesday
      t.boolean :wednesday
      t.boolean :thursday
      t.boolean :friday
      t.boolean :saturday
      t.boolean :sunday
      t.time :start_time

      t.timestamps
    end
  end

  def self.down
    drop_table :schedules
  end
end
