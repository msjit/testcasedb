class RemoveOldIdFieldsFromUploads < ActiveRecord::Migration
  def up
    change_table :uploads do |t|
        t.remove_references :test_case
        t.remove_references :result
    end
  end

  def down
    change_table :uploads do |t|
        t.references :test_case
        t.references :result
    end
    Upload.all.each do |upload|
      if upload.uploadable_type == "TestCase"
        upload.test_case_id = upload.uploadable_id
        upload.save
      elsif upload.uploadable_type == "Result"
        upload.result_id = upload.uploadable_id
        upload.save
      end
    end
  end
end
