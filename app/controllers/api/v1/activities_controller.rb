# frozen_string_literal: true

module Api
  module V1
    class ActivitiesController < BaseController
      before_action :set_course, only: [:index, :create]
      before_action :set_activity, only: [:update, :destroy]

      # Método: index
      # Descripción: Lista todas las actividades asociadas a un curso específico.
      # Parámetros: class_id (en URL).
      # Retorna: Lista JSON de actividades (status: 200 OK) o 404 si el curso no existe.
      def index
        activities = @course.activities
        render json: activities, status: :ok
      end

      # Método: create
      # Descripción: Crea una nueva actividad o juego asociado a una lección de este curso.
      # Parámetros: class_id (en URL), title, status, deadline, score, lesson_id, activity_type, content (en body).
      # Retorna: Objeto JSON de la actividad creada o error correspondiente.
      def create
        unless @course.user_id == @current_user.id || @current_user.admin?
          return render json: {
            error: I18n.t('api.activities.forbidden', default: 'Solo el profesor o un administrador puede gestionar las prácticas de esta clase.')
          }, status: :forbidden
        end

        activity = Activity.new(activity_params)

        if activity.save
          render json: {
            message: I18n.t('api.activities.created_success', default: '¡Genial! Tu nuevo juego educativo está listo para que todos practiquen.'),
            activity: activity
          }, status: :created
        else
          render json: { errors: activity.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Método: update
      # Descripción: Actualiza una actividad o juego existente.
      # Parámetros: id (en URL).
      # Retorna: Objeto JSON con la actividad actualizada o error correspondiente.
      def update
        unless @activity.lesson.course.user_id == @current_user.id || @current_user.admin?
          return render json: {
            error: I18n.t('api.activities.forbidden', default: 'Solo el profesor o un administrador puede gestionar las prácticas de esta clase.')
          }, status: :forbidden
        end

        if @activity.update(activity_params)
          render json: @activity, status: :ok
        else
          render json: { errors: @activity.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Método: destroy
      # Descripción: Elimina una actividad o juego interactivo de la lección y sus progresos dependientes.
      # Parámetros: id (en URL).
      # Retorna: 200 OK con mensaje de éxito o 403 Forbidden / 404 Not Found.
      def destroy
        unless @activity.lesson.course.user_id == @current_user.id || @current_user.admin?
          return render json: {
            error: I18n.t('api.activities.forbidden', default: 'Solo el profesor o un administrador puede gestionar las prácticas de esta clase.')
          }, status: :forbidden
        end

        @activity.destroy
        render json: {
          message: I18n.t('api.activities.deleted_success', default: 'Práctica eliminada correctamente.')
        }, status: :ok
      end

      private

      # Método: set_course
      # Descripción: Localiza el curso mediante el parámetro class_id.
      def set_course
        @course = Course.find_by(id: params[:class_id])
        return render json: {
          error: I18n.t('api.courses.not_found', default: 'No encontramos la clase indicada. ¡Verifica el enlace o busca otra clase!')
        }, status: :not_found unless @course
      end

      # Método: set_activity
      # Descripción: Localiza la actividad mediante su ID e incluye las asociaciones necesarias.
      def set_activity
        @activity = Activity.includes(lesson: :course).find_by(id: params[:id])
        return render json: {
          error: I18n.t('api.activities.not_found', default: 'No encontramos la práctica o juego interactivo.')
        }, status: :not_found unless @activity
      end

      # Método: activity_params
      # Descripción: Strong parameters para el modelo Activity, permitiendo el payload jsonb completo en content.
      def activity_params
        permitted = params.permit(:title, :status, :deadline, :score, :lesson_id, :activity_type)
        if params[:content].present?
          permitted[:content] = if params[:content].respond_to?(:permit!)
                                  params[:content].permit!.to_h
                                elsif params[:content].is_a?(Hash)
                                  params[:content]
                                else
                                  params[:content]
                                end
        end
        permitted
      end
    end
  end
end
