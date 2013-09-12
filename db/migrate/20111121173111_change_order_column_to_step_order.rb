class ChangeOrderColumnToStepOrder < ActiveRecord::Migration
  def self.up
    rename_column :steps, :order, :step_number
  end

  def self.down
    rename_column :steps, :step_number, :order
  end
end
