class AddStencilIdToAssignments < ActiveRecord::Migration
  def self.up
    add_column :assignments, :stencil_id, :integer
  end

  def self.down
    remove_column :assignments, :stencil_id
  end
end
