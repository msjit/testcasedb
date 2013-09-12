class ChangePlanCaseOrderColumnToCaseOrder < ActiveRecord::Migration
  def self.up
    rename_column :plan_cases, :order, :case_order
  end

  def self.down
    rename_column :plan_cases, :case_order, :order
  end
end
