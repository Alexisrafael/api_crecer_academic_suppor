class CreateSubjects < ActiveRecord::Migration[8.0]
  def change
    create_table :subjects do |t|
      t.string :name
      t.text :description
      t.string :icon_color
      t.boolean :is_active, default: true

      t.timestamps
    end
  end
end
