class AddActiveToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :active, :boolean
  end

  def self.down
    remove_column :users, :active
  end
end
