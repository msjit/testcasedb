class AddParentIdToStencils < ActiveRecord::Migration
  def self.up
    add_column :stencils, :parent_id, :integer
  end

  def self.down
    remove_column :stencils, :parent_id
  end
end
