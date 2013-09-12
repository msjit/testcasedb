class TagsTestcases < ActiveRecord::Migration
  def self.up
    create_table :tag_test_cases, :id => false do |t|
      t.integer :tag_id
      t.integer :test_case_id
    end
  end

  def self.down
    drop_table :tag_test_cases
  end
end
