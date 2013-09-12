class CreateCustomItems < ActiveRecord::Migration
  def self.up
    create_table :custom_items do |t|
      t.integer :test_case_id
      t.integer :test_plan_id
      t.integer :custom_field_id
      t.string :value

      t.timestamps
    end
  end

  def self.down
    drop_table :custom_items
  end
end
