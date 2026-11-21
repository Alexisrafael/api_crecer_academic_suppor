Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Rutas Públicas (Auth)
      post 'auth/register', to: 'auth#register'
      post 'auth/login', to: 'auth#login'
      post 'auth/refresh', to: 'auth#refresh'
      delete 'auth/logout', to: 'auth#logout'
      put 'auth/update_profile', to: 'auth#update_profile'
      get 'auth/me', to: 'profiles#show'
      get 'profile', to: 'profiles#show'

      # Rutas Protegidas
      # Dashboard y Progreso
      get 'dashboard', to: 'dashboard#index'
      get 'dashboard/history', to: 'dashboard#history'
      post 'progress', to: 'user_progresses#create'

      # Materias y Profesores
      resources :subjects, only: [:index, :show, :create, :update, :destroy] do
        # Profesores de una materia
        get 'teachers', to: 'subjects#teachers'

        # Clases (Cursos) de un profesor en la materia
        get 'teachers/:teacher_id/classes', to: 'courses#index'
        post 'teachers/:teacher_id/enroll', to: 'courses#enroll'

        # Gestión de Cursos por parte del profesor
        get 'my_classes', to: 'courses#my_courses'
        post 'classes', to: 'courses#create'
      end

      # Rutas para cursos (classes en la URL), actividades y lecciones
      resources :classes, controller: 'courses', only: [:show, :update, :destroy] do
        resources :activities, only: [:index, :create, :update, :destroy], shallow: true
        resources :lessons, only: [:index, :create, :update, :destroy], shallow: true
      end
    end
  end
end
