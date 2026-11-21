# frozen_string_literal: true

module Api
  module V1
    class CoursesController < BaseController
      # Método: index
      # Descripción: Obtiene los cursos (grupos) de un profesor para una materia específica, indicando si el alumno está inscrito.
      # Parámetros: subject_id, teacher_id (en URL).
      # Retorna: Lista JSON de cursos con estado de inscripción (status: 200 OK).
      def index
        courses = Course.where(subject_id: params[:subject_id], user_id: params[:teacher_id])
        course_ids = courses.map(&:id)
        enrolled_course_ids = Enrollment.where(user_id: @current_user.id, course_id: course_ids).pluck(:course_id).to_set

        response_data = courses.map do |course|
          {
            id: course.id,
            title: course.name,
            description: course.description,
            is_enrolled: enrolled_course_ids.include?(course.id)
          }
        end

        render json: response_data, status: :ok
      end

      # Método: show
      # Descripción: Busca y retorna la información de un curso individual por su ID.
      # Parámetros: id (en URL).
      # Retorna: Objeto JSON con los detalles del curso (status: 200 OK) o 404 Not Found si no existe.
      def show
        course = Course.includes(:subject).find_by(id: params[:id])
        if course
          is_enrolled = Enrollment.exists?(user_id: @current_user.id, course_id: course.id)
          render json: course.as_json.merge(
            title: course.name,
            is_enrolled: is_enrolled,
            subject_name: course.subject&.name
          ), status: :ok
        else
          render json: {
            error: I18n.t('api.courses.not_found', default: 'No encontramos la clase indicada. ¡Verifica el enlace o busca otra clase!')
          }, status: :not_found
        end
      end

      # Método: enroll
      # Descripción: Inscribe al estudiante en el curso dictado por el profesor para la materia especificada.
      # Parámetros: subject_id, teacher_id (en URL).
      # Retorna: Mensaje JSON de confirmación o errores de validación.
      def enroll
        course = Course.find_by(subject_id: params[:subject_id], user_id: params[:teacher_id])
        if course.nil?
          return render json: {
            error: I18n.t('api.courses.no_active_course', default: 'El profesor aún no ha publicado una clase para esta materia. ¡Vuelve pronto!')
          }, status: :not_found
        end

        enrollment = Enrollment.find_or_initialize_by(user_id: @current_user.id, course_id: course.id)
        if enrollment.save
          render json: {
            message: I18n.t('api.courses.enrolled_success', default: '¡Fantástico! Ya estás inscrito en esta clase. ¡A aprender!')
          }, status: :ok
        else
          render json: { errors: enrollment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Método: my_courses
      # Descripción: Lista los cursos que dicta el profesor autenticado para una materia específica.
      # Parámetros: subject_id (en URL).
      # Retorna: Lista JSON de cursos o 403 Forbidden si no es tutor ni admin.
      def my_courses
        if @current_user.user_type != 'tutor' && !@current_user.admin?
          return render json: {
            error: I18n.t('api.courses.teacher_required', default: 'Esta sección es solo para que los profesores organicen sus clases.')
          }, status: :forbidden
        end

        courses = Course.where(subject_id: params[:subject_id], user_id: @current_user.id)
        render json: courses.as_json(only: [:id, :name, :description]), status: :ok
      end

      # Método: create
      # Descripción: Crea un nuevo curso asignado a la materia y al profesor autenticado.
      # Parámetros: subject_id (en URL), name, description (en body).
      # Retorna: Objeto JSON del curso creado (status: 201 Created) o error correspondientes.
      def create
        if @current_user.user_type != 'tutor' && !@current_user.admin?
          return render json: {
            error: I18n.t('api.courses.teacher_required', default: 'Esta sección es solo para que los profesores organicen sus clases.')
          }, status: :forbidden
        end

        course = Course.new(course_params)
        course.subject_id = params[:subject_id]
        course.user_id = @current_user.id

        if course.save
          render json: course, status: :created
        else
          render json: { errors: course.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Método: update
      # Descripción: Actualiza un curso existente siempre que pertenezca al usuario autenticado o sea admin.
      # Parámetros: id (en URL), name, description (en body).
      # Retorna: Objeto JSON con el curso actualizado o 403/404/422.
      def update
        course = Course.find_by(id: params[:id])
        unless course
          return render json: {
            error: I18n.t('api.courses.not_found', default: 'No encontramos la clase indicada. ¡Verifica el enlace o busca otra clase!')
          }, status: :not_found
        end

        if course.user_id != @current_user.id && !@current_user.admin?
          return render json: {
            error: I18n.t('api.courses.forbidden', default: 'No tienes permiso para modificar esta clase.')
          }, status: :forbidden
        end

        if course.update(course_params)
          render json: course, status: :ok
        else
          render json: { errors: course.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Método: destroy
      # Descripción: Elimina un curso si pertenece al usuario actual o es administrador.
      # Parámetros: id (en URL).
      # Retorna: 200 OK, 404 si no existe o 403 si carece de permisos.
      def destroy
        course = Course.find_by(id: params[:id])
        unless course
          return render json: {
            error: I18n.t('api.courses.not_found', default: 'No encontramos la clase indicada. ¡Verifica el enlace o busca otra clase!')
          }, status: :not_found
        end

        if course.user_id != @current_user.id && !@current_user.admin?
          return render json: {
            error: I18n.t('api.courses.forbidden', default: 'No tienes permiso para modificar esta clase.')
          }, status: :forbidden
        end

        course.destroy
        head :ok
      end

      private

      # Método: course_params
      # Descripción: Strong parameters para el modelo Course.
      def course_params
        params.permit(:name, :description)
      end
    end
  end
end
