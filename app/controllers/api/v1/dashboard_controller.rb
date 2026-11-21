# frozen_string_literal: true

module Api
  module V1
    class DashboardController < BaseController
      # Método: index
      # Descripción: Proporciona las métricas consolidadas del panel de control del usuario autenticado
      #              (trofeos, actividades pendientes, última lección visualizada y progreso por materia).
      #              Optimizado sin consultas N+1 mediante eager loading y agrupamiento SQL.
      # Parámetros: Ninguno directo (usa @current_user).
      # Retorna: Objeto JSON con el resumen del dashboard (status: 200 OK).
      def index
        # Datos del usuario
        user_data = {
          first_name: @current_user.first_name,
          last_name: @current_user.last_name,
          email: @current_user.email,
          role: @current_user.admin? ? 'admin' : (@current_user.tutor? ? 'teacher' : 'student')
        }

        # Colecciones base
        activities = []
        last_video = nil
        subjects_progress = []

        if @current_user.student?
          # Obtener mis cursos inscritos con su materia pre-cargada
          my_course_ids = Enrollment.where(user_id: @current_user.id).pluck(:course_id)
          my_courses = Course.includes(:subject).where(id: my_course_ids)
          my_lesson_ids = Lesson.where(course_id: my_course_ids).pluck(:id)

          # IDs de actividades completadas por el alumno
          completed_activity_ids = UserProgress.where(user_id: @current_user.id, is_completed: true)
                                               .where.not(activity_id: nil)
                                               .pluck(:activity_id)

          # ACTIVIDADES PENDIENTES (Eager loading profundo para evitar N+1 en lesson, course y subject)
          activities = Activity.includes(lesson: { course: :subject })
                               .where(lesson_id: my_lesson_ids)
                               .where.not(id: completed_activity_ids)
                               .order(created_at: :desc)
                               .limit(5)
                               .map do |act|
            {
              id: act.id,
              title: act.title,
              subject: act.lesson.course.subject.name,
              course_id: act.lesson.course.id,
              status: 'pending',
              score: nil
            }
          end

          # ÚLTIMO VIDEO / LECCIÓN (Carga eager loading para eliminar N+1)
          last_lesson_progress = UserProgress.includes(lesson: { course: :subject })
                                             .where(user_id: @current_user.id)
                                             .where.not(lesson_id: nil)
                                             .order(updated_at: :desc)
                                             .first

          if last_lesson_progress
            lesson = last_lesson_progress.lesson
            course = lesson.course
            next_lesson = Lesson.where(course_id: course.id).where("id > ?", lesson.id).order(id: :asc).first

            last_video = {
              subject: course.subject.name,
              title: lesson.title,
              duration: "Vista recientemente",
              hasContinuity: !next_lesson.nil?,
              nextVideo: next_lesson ? next_lesson.title : "¡Curso completado!",
              course_id: course.id
            }
          end

          # PROGRESO POR MATERIA (Optimización N+1: Agrupamiento previo por course_id con solo 2 queries SQL)
          completed_lesson_ids = UserProgress.where(user_id: @current_user.id, is_completed: true)
                                             .where.not(lesson_id: nil)
                                             .pluck(:lesson_id)

          total_lessons_by_course = Lesson.where(course_id: my_course_ids).group(:course_id).count
          completed_lessons_by_course = Lesson.where(course_id: my_course_ids, id: completed_lesson_ids).group(:course_id).count

          subjects_progress = my_courses.map do |course|
            total_course_lessons = total_lessons_by_course[course.id] || 0
            completed_course_lessons = completed_lessons_by_course[course.id] || 0

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

        trophies_count = UserProgress.where(user_id: @current_user.id, is_completed: true)
                                     .where.not(activity_id: nil)
                                     .count

        render json: {
          user: user_data,
          total_trophies: trophies_count,
          activities: activities,
          last_video: last_video,
          subjects_progress: subjects_progress
        }, status: :ok
      end

      # Método: history
      # Descripción: Retorna el historial completo de actividades realizadas por el estudiante agrupadas por materia,
      #              con conteo total de trofeos y optimización en memoria sin re-consultas.
      # Parámetros: Ninguno directo.
      # Retorna: Objeto JSON con el historial por materia (status: 200 OK).
      def history
        progresses = UserProgress.where(user_id: @current_user.id)
                                 .where.not(activity_id: nil)
                                 .includes(activity: { lesson: { course: :subject } })
                                 .order(updated_at: :desc)

        grouped_data = {}
        total_trophies = 0

        progresses.each do |p|
          activity = p.activity
          next unless activity

          total_trophies += 1 if p.is_completed?
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
          total_trophies: total_trophies,
          history_by_subject: grouped_data.values
        }, status: :ok
      end
    end
  end
end
