class CreateTasks < ActiveRecord::Migration
  def self.up
    create_table :tasks do |t|
      t.integer :user_id
      t.integer :task
      t.text :description
      t.date :due_date
      t.date :completion_date
      t.integer :status

      t.timestamps
    end
  end

  def self.down
    drop_table :tasks
  end
end
