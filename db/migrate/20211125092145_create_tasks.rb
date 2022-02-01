class CreateTasks < ActiveRecord::Migration[6.1]
  def change
    create_table :tasks do |t|
      t.string :label
      t.integer :status

      t.timestamps
    end
  end
end
