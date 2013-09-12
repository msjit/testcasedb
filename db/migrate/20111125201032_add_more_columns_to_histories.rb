class AddMoreColumnsToHistories < ActiveRecord::Migration
  def self.up
    add_column :histories, :product_id, :integer
    add_column :histories, :category_id, :integer
  end

  def self.down
    remove_column :histories, :category_id
    remove_column :histories, :product_id
  end
end
