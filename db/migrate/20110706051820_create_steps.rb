class CreateSteps < ActiveRecord::Migration
  def self.up
    create_table :steps do |t|
      t.text :action
      t.text :result
      t.integer :order

      t.timestamps
    end
  end

  def self.down
    drop_table :steps
  end
end
