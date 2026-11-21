# frozen_string_literal: true

module Api
  module V1
    class SubjectsController < BaseController
      # Método: index
      # Descripción: Lista todas las materias activas en la plataforma.
      # Parámetros: Ninguno.
      # Retorna: Lista JSON de materias activas (status: 200 OK).
      def index
        subjects = Subject.where(is_active: true)
        render json: subjects.as_json(only: [:id, :name, :description, :icon_color, :is_active]), status: :ok
      end

      # Método: show
      # Descripción: Busca y retorna los detalles de una materia específica por su ID.
      # Parámetros: id (en URL).
      # Retorna: Objeto JSON con la materia (status: 200 OK) o 404 Not Found si no existe.
      def show
        subject = Subject.find_by(id: params[:id])
        if subject
          render json: subject, status: :ok
        else
          render json: { error: I18n.t('api.subjects.not_found', default: 'No pudimos encontrar la materia solicitada.') }, status: :not_found
        end
      end

      # Método: create
      # Descripción: Crea una nueva materia académica (restringido a administradores).
      # Parámetros: name, description, icon_color, is_active.
      # Retorna: Objeto JSON con la materia creada (status: 201) o 403 Forbidden / 422 Unprocessable.
      def create
        unless @current_user.admin?
          return render json: { error: I18n.t('api.subjects.unauthorized', default: 'Solo los administradores pueden gestionar las materias.') }, status: :forbidden
        end

        subject = Subject.new(subject_params)
        if subject.save
          render json: subject, status: :created
        else
          render json: { errors: subject.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Método: update
      # Descripción: Actualiza una materia existente (restringido a administradores).
      # Parámetros: id (en URL), name, description, icon_color, is_active.
      # Retorna: Objeto JSON con la materia actualizada (status: 200) o error correspondiente.
      def update
        unless @current_user.admin?
          return render json: { error: I18n.t('api.subjects.unauthorized', default: 'Solo los administradores pueden gestionar las materias.') }, status: :forbidden
        end

        subject = Subject.find_by(id: params[:id])
        unless subject
          return render json: { error: I18n.t('api.subjects.not_found', default: 'No pudimos encontrar la materia solicitada.') }, status: :not_found
        end

        if subject.update(subject_params)
          render json: subject, status: :ok
        else
          render json: { errors: subject.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Método: destroy
      # Descripción: Elimina una materia académica (restringido a administradores).
      # Parámetros: id (en URL).
      # Retorna: 200 OK si se eliminó con éxito, 404 si no existe, o 403 si el rol no es administrador.
      def destroy
        unless @current_user.admin?
          return render json: { error: I18n.t('api.subjects.unauthorized', default: 'Solo los administradores pueden gestionar las materias.') }, status: :forbidden
        end

        subject = Subject.find_by(id: params[:id])
        unless subject
          return render json: { error: I18n.t('api.subjects.not_found', default: 'No pudimos encontrar la materia solicitada.') }, status: :not_found
        end

        subject.destroy
        head :ok
      end

      # Método: teachers
      # Descripción: Lista los profesores que imparten clases en la materia indicada.
      # Parámetros: subject_id (en URL).
      # Retorna: Lista de profesores con su información básica.
      def teachers
        teacher_ids = Course.where(subject_id: params[:subject_id]).pluck(:user_id).uniq
        teachers = User.where(id: teacher_ids).map do |t|
          {
            id: t.id,
            first_name: t.first_name,
            last_name: t.last_name,
            description: "Profesor"
          }
        end
        render json: teachers, status: :ok
      end

      private

      # Método: subject_params
      # Descripción: Strong parameters para atributos permitidos de Subject.
      def subject_params
        params.permit(:name, :description, :icon_color, :is_active)
      end
    end
  end
end
