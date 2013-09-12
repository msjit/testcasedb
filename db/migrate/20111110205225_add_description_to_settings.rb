class AddDescriptionToSettings < ActiveRecord::Migration
  def self.up
    add_column :settings, :description, :string
  end

  def self.down
    remove_column :settings, :description
  end
end
