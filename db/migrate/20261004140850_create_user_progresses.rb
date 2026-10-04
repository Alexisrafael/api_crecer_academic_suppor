class CreateUserProgresses < ActiveRecord::Migration[8.0]
  def change
    create_table :user_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lesson, null: false, foreign_key: true
      t.references :activity, null: false, foreign_key: true
      t.integer :progress_percent
      t.boolean :is_completed
      t.integer :last_video_position

      t.timestamps
    end
  end
end
