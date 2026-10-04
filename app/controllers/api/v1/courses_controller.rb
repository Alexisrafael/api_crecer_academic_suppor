module Api
  module V1
    class CoursesController < BaseController
      def index
        # Obtener los cursos (grupos) de un profesor para una materia específica
        courses = Course.where(subject_id: params[:subject_id], user_id: params[:teacher_id])
        
        response_data = courses.map do |course|
          {
            id: course.id,
            title: course.name,
            description: course.description,
            is_enrolled: Enrollment.exists?(user_id: @current_user.id, course_id: course.id)
          }
        end
        
        render json: response_data, status: :ok
      end

      def enroll
        course = Course.find_by(subject_id: params[:subject_id], user_id: params[:teacher_id])
        if course.nil?
          return render json: { error: 'El profesor no tiene un curso activo para esta materia' }, status: :not_found
        end

        enrollment = Enrollment.find_or_initialize_by(user_id: @current_user.id, course_id: course.id)
        if enrollment.save
          render json: { message: 'Inscrito correctamente al grupo del profesor' }, status: :ok
        else
          render json: { errors: enrollment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def my_courses
        if @current_user.user_type != 'tutor' && @current_user.role != 'admin'
          return render json: { error: 'Solo profesores pueden ver sus grupos dictados' }, status: :forbidden
        end

        courses = Course.where(subject_id: params[:subject_id], user_id: @current_user.id)
        render json: courses.as_json(only: [:id, :name, :description]), status: :ok
      end

      def create
        if @current_user.user_type != 'tutor' && @current_user.role != 'admin'
          return render json: { error: 'Solo profesores pueden crear cursos' }, status: :forbidden
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

      def update
        course = Course.find(params[:id])
        if course.user_id != @current_user.id && @current_user.role != 'admin'
          return render json: { error: 'No tienes permiso para editar este curso' }, status: :forbidden
        end

        if course.update(course_params)
          render json: course, status: :ok
        else
          render json: { errors: course.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        course = Course.find(params[:id])
        if course.user_id != @current_user.id && @current_user.role != 'admin'
          return render json: { error: 'No tienes permiso para eliminar este curso' }, status: :forbidden
        end

        course.destroy
        head :ok
      end

      private

      def course_params
        params.permit(:name, :description)
      end
    end
  end
end
