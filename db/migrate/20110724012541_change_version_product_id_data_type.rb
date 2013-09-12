class ChangeVersionProductIdDataType < ActiveRecord::Migration
  def self.up
    change_table :versions do |t|
      t.change :product_id, :integer
    end
  end

  def self.down
    change_table :versions do |t|
      t.change :product_id, :string
    end
  end
end
