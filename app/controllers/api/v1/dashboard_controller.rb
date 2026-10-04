module Api
  module V1
    class DashboardController < BaseController
      def index
        # User details
        user_data = {
          first_name: @current_user.first_name,
          last_name: @current_user.last_name,
          email: @current_user.email,
          role: @current_user.role == 'admin' ? 'admin' : (@current_user.user_type == 'tutor' ? 'teacher' : 'student')
        }

        # Arrays base vacíos
        activities = []
        last_video = nil
        subjects_progress = []

        if @current_user.user_type == 'student'
          # Obtener mis cursos
          my_course_ids = Enrollment.where(user_id: @current_user.id).pluck(:course_id)
          my_courses = Course.includes(:subject).where(id: my_course_ids)
          my_lesson_ids = Lesson.where(course_id: my_course_ids).pluck(:id)
          
          # Trofeos completados
          completed_activity_ids = UserProgress.where(user_id: @current_user.id, is_completed: true).where.not(activity_id: nil).pluck(:activity_id)

          # ACTIVIDADES PENDIENTES (Las más recientes que no han sido completadas)
          activities = Activity.includes(lesson: { course: :subject }).where(lesson_id: my_lesson_ids).where.not(id: completed_activity_ids).order(created_at: :desc).limit(5).map do |act|
            {
              id: act.id,
              title: act.title,
              subject: act.lesson.course.subject.name,
              course_id: act.lesson.course.id,
              status: 'pending',
              score: nil
            }
          end

          # ÚLTIMO VIDEO / LECCIÓN
          last_lesson_progress = UserProgress.where(user_id: @current_user.id).where.not(lesson_id: nil).order(updated_at: :desc).first
          if last_lesson_progress
            lesson = last_lesson_progress.lesson
            course = lesson.course
            next_lesson = Lesson.where(course_id: course.id).where("id > ?", lesson.id).order(id: :asc).first
            
            last_video = {
              subject: course.subject.name,
              title: lesson.title,
              duration: "Vista recientemente",
              hasContinuity: !!next_lesson,
              nextVideo: next_lesson ? next_lesson.title : "¡Curso completado!",
              course_id: course.id
            }
          end

          # PROGRESO POR MATERIA
          completed_lesson_ids = UserProgress.where(user_id: @current_user.id, is_completed: true).where.not(lesson_id: nil).pluck(:lesson_id)
          
          subjects_progress = my_courses.map do |course|
            total_course_lessons = Lesson.where(course_id: course.id).count
            completed_course_lessons = Lesson.where(course_id: course.id, id: completed_lesson_ids).count
            
            progress_percent = total_course_lessons > 0 ? ((completed_course_lessons.to_f / total_course_lessons) * 100).round : 0
            
            {
              name: course.subject.name,
              course_name: course.name,
              progress: progress_percent,
              classesTaken: completed_course_lessons > 0,
              color: course.subject.icon_color || "bg-blue-500"
            }
          end
        end

        trophies_count = UserProgress.where(user_id: @current_user.id, is_completed: true).where.not(activity_id: nil).count

        render json: {
          user: user_data,
          total_trophies: trophies_count,
          activities: activities,
          last_video: last_video,
          subjects_progress: subjects_progress
        }, status: :ok
      end
      def history
        # Obtener progresos de actividades
        progresses = UserProgress.where(user_id: @current_user.id).where.not(activity_id: nil).includes(activity: { lesson: { course: :subject } })
        
        grouped_data = {}
        progresses.each do |p|
          activity = p.activity
          next unless activity
          
          subject = activity.lesson.course.subject
          
          grouped_data[subject.id] ||= {
            name: subject.name,
            color: subject.icon_color || 'bg-sky-500',
            activities: []
          }
          
          grouped_data[subject.id][:activities] << {
            id: activity.id,
            title: activity.title,
            course_name: activity.lesson.course.name,
            lesson_title: activity.lesson.title,
            completed_at: p.updated_at.strftime("%d/%m/%Y %I:%M %p"),
            score: p.progress_percent,
            status: p.is_completed ? 'Lograda' : 'Fallida'
          }
        end

        render json: {
          total_trophies: progresses.where(is_completed: true).count,
          history_by_subject: grouped_data.values
        }, status: :ok
      end
    end
  end
end
