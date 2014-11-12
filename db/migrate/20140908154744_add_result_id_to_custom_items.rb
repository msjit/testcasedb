class AddResultIdToCustomItems < ActiveRecord::Migration
  def self.up
    add_column :custom_items, :result_id, :integer
  end

  def self.down
    remove_column :custom_items, :result_id
  end
end
