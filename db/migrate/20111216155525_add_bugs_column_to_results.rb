class AddBugsColumnToResults < ActiveRecord::Migration
  def self.up
    add_column :results, :bugs, :string
  end

  def self.down
    remove_column :results, :bugs
  end
end
