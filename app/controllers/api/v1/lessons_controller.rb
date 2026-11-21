# frozen_string_literal: true

module Api
  module V1
    class LessonsController < BaseController
      before_action :set_course, only: [:index, :create]
      before_action :set_lesson, only: [:update, :destroy]

      # Método: index
      # Descripción: Lista todas las lecciones del curso junto a sus actividades y estados de completitud del estudiante.
      # Parámetros: class_id (en URL).
      # Retorna: Objeto JSON con lessons, completed_lesson_ids y completed_activity_ids (status: 200 OK).
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

      # Método: create
      # Descripción: Crea una nueva lección en el curso indicado (solo para el profesor titular o admin).
      # Parámetros: class_id (en URL), title, description, video_url (en body).
      # Retorna: Objeto JSON con la lección creada (status: 201 Created) o error de validación/permisos.
      def create
        unless @course.user_id == @current_user.id || @current_user.admin?
          return render json: {
            error: I18n.t('api.lessons.forbidden_create', default: 'Solo el profesor titular o un administrador puede agregar clases a este curso.')
          }, status: :forbidden
        end

        lesson = @course.lessons.build(lesson_params)
        if lesson.save
          render json: lesson, status: :created
        else
          render json: { errors: lesson.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Método: update
      # Descripción: Actualiza los detalles de una lección (título, descripción, video).
      # Parámetros: id (en URL).
      # Retorna: Objeto JSON con la lección actualizada (status: 200 OK) o error correspondiente.
      def update
        unless @lesson.course.user_id == @current_user.id || @current_user.admin?
          return render json: {
            error: I18n.t('api.lessons.forbidden_edit', default: 'Solo el profesor de este curso puede editar esta clase.')
          }, status: :forbidden
        end

        if @lesson.update(lesson_params)
          render json: @lesson, status: :ok
        else
          render json: { errors: @lesson.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Método: destroy
      # Descripción: Elimina una lección, sus actividades dependientes y los progresos asociados en cascada.
      # Parámetros: id (en URL).
      # Retorna: 200 OK si se eliminó con éxito, 403 Forbidden o 404 Not Found.
      def destroy
        unless @lesson.course.user_id == @current_user.id || @current_user.admin?
          return render json: {
            error: I18n.t('api.lessons.forbidden_delete', default: 'Solo el profesor de este curso puede eliminar esta clase.')
          }, status: :forbidden
        end

        @lesson.destroy
        head :ok
      end

      private

      # Método: set_course
      # Descripción: Localiza el curso mediante params[:class_id].
      def set_course
        @course = Course.find_by(id: params[:class_id])
        return render json: {
          error: I18n.t('api.courses.not_found', default: 'No encontramos la clase indicada. ¡Verifica el enlace o busca otra clase!')
        }, status: :not_found unless @course
      end

      # Método: set_lesson
      # Descripción: Localiza la lección e incluye su curso asociado para verificación de permisos.
      def set_lesson
        @lesson = Lesson.includes(:course).find_by(id: params[:id])
        return render json: {
          error: I18n.t('api.lessons.not_found', default: '¡Vaya! No encontramos esa lección. ¿Probamos con otra clase?')
        }, status: :not_found unless @lesson
      end

      # Método: lesson_params
      # Descripción: Strong parameters para el modelo Lesson.
      def lesson_params
        params.permit(:title, :description, :video_url)
      end
    end
  end
end
