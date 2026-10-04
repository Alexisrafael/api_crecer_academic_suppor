class CreateActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :activities do |t|
      t.string :title
      t.integer :status, default: 1
      t.datetime :deadline
      t.string :score
      t.references :lesson, null: false, foreign_key: true

      t.timestamps
    end
  end
end
