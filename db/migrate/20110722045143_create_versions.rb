class CreateVersions < ActiveRecord::Migration
  def self.up
    create_table :versions do |t|
      t.string :version
      t.text :description
      t.integer :product_id

      t.timestamps
    end
  end

  def self.down
    drop_table :versions
  end
end
