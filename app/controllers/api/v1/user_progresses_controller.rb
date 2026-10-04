module Api
  module V1
    class UserProgressesController < Api::V1::BaseController
      # POST /api/v1/progress
      def create
        # Find existing progress by lesson_id if provided, else by activity_id
        progress = nil
        if params[:lesson_id].present?
          progress = UserProgress.find_or_initialize_by(
            user_id: current_user.id,
            lesson_id: params[:lesson_id]
          )
        elsif params[:activity_id].present?
          progress = UserProgress.find_or_initialize_by(
            user_id: current_user.id,
            activity_id: params[:activity_id]
          )
        else
          return render json: { error: "Must provide lesson_id or activity_id" }, status: :unprocessable_entity
        end
        
        progress.progress_percent = params[:progress_percent]
        progress.is_completed = params[:is_completed]
        progress.last_video_position = params[:last_video_position]
        
        if progress.save
          progress.touch # Fuerza que se actualice la fecha/hora en el historial
          render json: { success: true, progress: progress }, status: :ok
        else
          render json: { errors: progress.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
