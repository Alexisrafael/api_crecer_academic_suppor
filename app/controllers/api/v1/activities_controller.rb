module Api
  module V1
    class ActivitiesController < BaseController
      before_action :set_course, only: [:index, :create]
      before_action :set_activity, only: [:update, :destroy]

      def index
        activities = @course.activities
        render json: activities, status: :ok
      end

      def create
        if @course.user_id != @current_user.id && @current_user.role != 'admin'
          return render json: { error: 'No autorizado' }, status: :forbidden
        end

        # Asumimos que se envía lesson_id en el payload para saber a qué clase pertenece
        activity = Activity.new(activity_params)
        
        if activity.save
          render json: activity, status: :created
        else
          render json: { errors: activity.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @activity.lesson.course.user_id != @current_user.id && @current_user.role != 'admin'
          return render json: { error: 'No autorizado' }, status: :forbidden
        end

        if @activity.update(activity_params)
          render json: @activity, status: :ok
        else
          render json: { errors: @activity.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @activity.lesson.course.user_id != @current_user.id && @current_user.role != 'admin'
          return render json: { error: 'No autorizado' }, status: :forbidden
        end

        @activity.destroy
        head :ok
      end

      private

      def set_course
        @course = Course.find(params[:class_id])
      end

      def set_activity
        @activity = Activity.find(params[:id])
      end

      def activity_params
        params.permit(:title, :status, :deadline, :score, :lesson_id, :activity_type, content: {})
      end
    end
  end
end
