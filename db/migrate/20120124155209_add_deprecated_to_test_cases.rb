class AddDeprecatedToTestCases < ActiveRecord::Migration
  def self.up
    add_column :test_cases, :deprecated, :boolean, :default => 0
  end

  def self.down
    remove_column :test_cases, :deprecated
  end
end
