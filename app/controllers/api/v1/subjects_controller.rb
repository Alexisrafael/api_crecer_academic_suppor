module Api
  module V1
    class SubjectsController < BaseController
      def index
        subjects = Subject.where(is_active: true)
        render json: subjects.as_json(only: [:id, :name, :description, :icon_color, :is_active]), status: :ok
      end

      def create
        if @current_user.role != 'admin'
          return render json: { error: 'No autorizado' }, status: :forbidden
        end

        subject = Subject.new(subject_params)
        if subject.save
          render json: subject, status: :created
        else
          render json: { errors: subject.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @current_user.role != 'admin'
          return render json: { error: 'No autorizado' }, status: :forbidden
        end

        subject = Subject.find(params[:id])
        if subject.update(subject_params)
          render json: subject, status: :ok
        else
          render json: { errors: subject.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @current_user.role != 2
          return render json: { error: 'No autorizado' }, status: :forbidden
        end

        subject = Subject.find(params[:id])
        subject.destroy
        head :ok
      end

      def teachers
        # Obtener profesores que tienen al menos un curso (grupo) en esta materia
        teacher_ids = Course.where(subject_id: params[:subject_id]).pluck(:user_id).uniq
        teachers = User.where(id: teacher_ids).map do |t|
          {
            id: t.id,
            first_name: t.first_name,
            last_name: t.last_name,
            description: "Profesor" # Podría extraerse de un campo profile_description en el futuro
          }
        end
        render json: teachers, status: :ok
      end

      private

      def subject_params
        params.permit(:name, :description, :icon_color, :is_active)
      end
    end
  end
end
