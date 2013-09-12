class CreateTestTypes < ActiveRecord::Migration
  def self.up
    create_table :test_types do |t|
      t.string :name
      t.text :description
      t.timestamp :created

      t.timestamps
    end
  end

  def self.down
    drop_table :test_types
  end
end
