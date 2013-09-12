class AddRoleToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :role, :integer, :limit => 1 
  end

  def self.down
    remove_column :users, :role
  end
end
