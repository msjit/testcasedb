class CreateStencils < ActiveRecord::Migration
  def self.up
    create_table :stencils do |t|
      t.integer :product_id
      t.string :name
      t.text :description
      t.integer :version, :limit => 2, :default => 1
      t.integer :status, :limit => 2
      t.boolean :deprecated, :default => 0
      t.integer :created_by_id
      t.integer :modified_by_id

      t.timestamps
    end
  end

  def self.down
    drop_table :stencils
  end
end
