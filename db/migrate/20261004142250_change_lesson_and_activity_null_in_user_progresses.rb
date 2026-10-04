class ChangeLessonAndActivityNullInUserProgresses < ActiveRecord::Migration[8.0]
  def change
    change_column_null :user_progresses, :lesson_id, true
    change_column_null :user_progresses, :activity_id, true
  end
end
