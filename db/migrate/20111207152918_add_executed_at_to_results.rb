class AddExecutedAtToResults < ActiveRecord::Migration
  def self.up
    add_column :results, :executed_at, :datetime
  end

  def self.down
    remove_column :results, :executed_at
  end
end
