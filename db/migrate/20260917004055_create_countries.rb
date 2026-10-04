class CreateCountries < ActiveRecord::Migration[8.0]
  def change
    create_table :countries do |t|
      t.string :name
      t.string :iso2, limit: 2
      t.string :iso3, limit: 3
      t.string :phone_code
      t.string :currency
      t.string :language

      t.timestamps
    end
  end
end
