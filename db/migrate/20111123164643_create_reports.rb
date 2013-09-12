class CreateReports < ActiveRecord::Migration
  def self.up
    create_table :reports do |t|
      t.integer :product_id
      t.integer :version_id
      t.date :start_date
      t.date :end_date
      t.string :report_type

      t.timestamps
    end
  end

  def self.down
    drop_table :reports
  end
end
