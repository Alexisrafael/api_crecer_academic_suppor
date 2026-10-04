module Api
  module V1
    class LessonsController < BaseController
      before_action :set_course, only: [:index, :create]
      before_action :set_lesson, only: [:update, :destroy]

      def index
        lessons = @course.lessons.includes(:activities)
        
        # Obtener progresos del usuario actual
        completed_lessons = UserProgress.where(user_id: @current_user.id, lesson_id: lessons.pluck(:id), is_completed: true).pluck(:lesson_id)
        activities_ids = Activity.where(lesson_id: lessons.pluck(:id)).pluck(:id)
        completed_activities = UserProgress.where(user_id: @current_user.id, activity_id: activities_ids, is_completed: true).pluck(:activity_id)

        render json: {
          lessons: lessons.as_json(include: :activities),
          completed_lesson_ids: completed_lessons.compact,
          completed_activity_ids: completed_activities.compact
        }, status: :ok
      end

      def create
        if @course.user_id != @current_user.id && @current_user.role != 'admin'
          return render json: { error: 'No tienes permiso para agregar clases a este curso' }, status: :forbidden
        end

        lesson = @course.lessons.build(lesson_params)
        if lesson.save
          render json: lesson, status: :created
        else
          render json: { errors: lesson.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @lesson.course.user_id != @current_user.id && @current_user.role != 'admin'
          return render json: { error: 'No tienes permiso para editar' }, status: :forbidden
        end

        if @lesson.update(lesson_params)
          render json: @lesson, status: :ok
        else
          render json: { errors: @lesson.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @lesson.course.user_id != @current_user.id && @current_user.role != 'admin'
          return render json: { error: 'No tienes permiso para eliminar' }, status: :forbidden
        end

        @lesson.destroy
        head :ok
      end

      private

      def set_course
        @course = Course.find(params[:class_id])
      end

      def set_lesson
        @lesson = Lesson.find(params[:id])
      end

      def lesson_params
        params.permit(:title, :description, :video_url)
      end
    end
  end
end
