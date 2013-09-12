class AddUploadColumnsToUpload < ActiveRecord::Migration
  def self.up
    add_column :uploads, :upload_file_name,    :string
    add_column :uploads, :upload_content_type, :string
    add_column :uploads, :upload_file_size,    :integer
    add_column :uploads, :upload_updated_at,   :datetime
  end

  def self.down
    remove_column :uploads, :upload_file_name
    remove_column :uploads, :upload_content_type
    remove_column :uploads, :upload_file_size
    remove_column :uploads, :upload_updated_at
  end
end
