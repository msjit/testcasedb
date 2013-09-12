class AddStencilIdToHistories < ActiveRecord::Migration
  def self.up
    add_column :histories, :stencil_id, :integer
  end

  def self.down
    remove_column :histories, :stencil_id
  end
end
