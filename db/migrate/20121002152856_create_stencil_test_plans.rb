class CreateStencilTestPlans < ActiveRecord::Migration
  def self.up
    create_table :stencil_test_plans do |t|
      t.integer :stencil_id
      t.integer :test_plan_id
      t.integer :device_id
      t.integer :plan_order

      t.timestamps
    end
  end

  def self.down
    drop_table :stencil_test_plans
  end
end
