class AddCategoryIdToTestCase < ActiveRecord::Migration
  def self.up
    add_column :test_cases, :category_id, :integer
  end

  def self.down
    remove_column :test_cases, :category_id
  end
end
