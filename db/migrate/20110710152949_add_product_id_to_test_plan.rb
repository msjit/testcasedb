class AddProductIdToTestPlan < ActiveRecord::Migration
  def self.up
          add_column :test_plans, :product_id, :integer
  end

  def self.down
          remove_column :test_plans, :product_id
  end

end
