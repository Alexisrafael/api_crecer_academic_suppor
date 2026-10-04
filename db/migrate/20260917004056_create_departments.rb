class CreateDepartments < ActiveRecord::Migration[8.0]
  def change
    create_table :departments do |t|
      t.string :name
      t.string :code
      t.string :postal_code
      t.references :country, null: false, foreign_key: true

      t.timestamps
    end
  end
end
