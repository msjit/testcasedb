class CreateCustomFields < ActiveRecord::Migration
  def self.up
    create_table :custom_fields do |t|
      t.string :item_type, :limit => 15
      t.string :field_name
      t.string :field_type, :limit => 15
      t.text :accepted_values
      t.boolean :active, :default => true

      t.timestamps
    end
  end

  def self.down
    drop_table :custom_fields
  end
end
