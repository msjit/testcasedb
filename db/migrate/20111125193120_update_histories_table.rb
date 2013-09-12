class UpdateHistoriesTable < ActiveRecord::Migration
  def self.up
    remove_column :histories, :result_case_id
    add_column :histories, :result_id, :integer
    add_column :histories, :assignment_id, :integer
  end

  def self.down
    add_column :histories, :result_case_id, :integer
    remove_column :histories, :result_id
    remove_column :histories, :assignment_id
  end
end
