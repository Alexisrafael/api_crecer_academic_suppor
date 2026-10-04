class AddTypeAndContentToActivities < ActiveRecord::Migration[8.0]
  def change
    add_column :activities, :activity_type, :string
    add_column :activities, :content, :jsonb
  end
end
