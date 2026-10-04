class MakeLocationFieldsOptionalInUsers < ActiveRecord::Migration[8.0]
  def change
    change_column_null :users, :plan_id, true
    change_column_null :users, :country_id, true
    change_column_null :users, :department_id, true
    change_column_null :users, :city_id, true
  end
end
