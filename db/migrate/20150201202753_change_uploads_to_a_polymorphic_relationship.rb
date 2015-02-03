class ChangeUploadsToAPolymorphicRelationship < ActiveRecord::Migration
  def up
    change_table :uploads do |t|
        t.references :uploadable, :polymorphic => true
    end
    Upload.all.each do |upload|
      if upload.test_case_id
        upload.uploadable_type = "TestCase"
        upload.uploadable_id = upload.test_case_id
        upload.save
      elsif upload.result_id
        upload.uploadable_type = "Result"
        upload.uploadable_id = upload.result_id
        upload.save
      end
    end
  end

  def down
    change_table :uploads do |t|
        t.remove_references :uploadable, :polymorphic => true
    end
  end
end
