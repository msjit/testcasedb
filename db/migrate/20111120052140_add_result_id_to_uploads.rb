class AddResultIdToUploads < ActiveRecord::Migration
  def self.up
    add_column :uploads, :result_id, :integer
  end

  def self.down
    remove_column :uploads, :result_id
  end
end
