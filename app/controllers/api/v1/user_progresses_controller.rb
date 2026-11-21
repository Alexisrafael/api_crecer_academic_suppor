# frozen_string_literal: true

module Api
  module V1
    class UserProgressesController < Api::V1::BaseController
      # Método: create
      # Descripción: Registra o actualiza el progreso formativo del estudiante en una lección o práctica interactiva.
      # Parámetros: lesson_id (opcional), activity_id (opcional), progress_percent, is_completed, last_video_position.
      # Retorna: Objeto JSON con mensaje motivador y el registro de progreso (status: 200 OK).
      def create
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
          return render json: {
            error: I18n.t('api.progress.missing_identifier', default: '¡Ups! Debes indicar una lección o una práctica para guardar tu avance.')
          }, status: :unprocessable_entity
        end

        progress.progress_percent = params[:progress_percent]
        progress.is_completed = params[:is_completed]
        progress.last_video_position = params[:last_video_position]

        if progress.save
          progress.touch # Actualiza timestamp para reflejar actividad reciente en el aula
          render json: {
            success: true,
            message: I18n.t('api.progress.saved_success', default: '¡Excelente esfuerzo! Tu progreso se guardó exitosamente.'),
            progress: progress
          }, status: :ok
        else
          render json: { errors: progress.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
