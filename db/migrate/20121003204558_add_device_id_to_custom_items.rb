class AddDeviceIdToCustomItems < ActiveRecord::Migration
  def self.up
    add_column :custom_items, :device_id, :integer
  end

  def self.down
    remove_column :custom_items, :device_id
  end
end
