class AddDeviceIdToResults < ActiveRecord::Migration
  def self.up
    add_column :results, :device_id, :integer
  end

  def self.down
    remove_column :results, :device_id
  end
end
