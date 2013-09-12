class RemoveTestTypeCreated < ActiveRecord::Migration
  def self.up
	  remove_column :test_types, :created
  end

  def self.down
	  add_column :test_types, :created, :timestamp
  end
end
