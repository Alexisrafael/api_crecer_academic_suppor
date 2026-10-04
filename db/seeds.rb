# db/seeds.rb

puts "Limpiando base de datos..."
Activity.destroy_all
Lesson.destroy_all
Enrollment.destroy_all
Course.destroy_all
Subject.destroy_all
User.destroy_all

puts "Creando usuarios..."
# Estudiante
student = User.create!(
  email: "estudiante@ejemplo.com",
  password: "password123",
  first_name: "Juan",
  last_name: "Pérez",
  user_type: :student,
  role: :user,
  status: :active
)

# Profesor
teacher = User.create!(
  email: "profesor@ejemplo.com",
  password: "password123",
  first_name: "Albert",
  last_name: "Einstein",
  user_type: :tutor,
  role: :user,
  status: :active
)

# Admin
admin = User.create!(
  email: "admin@ejemplo.com",
  password: "password123",
  first_name: "Admin",
  last_name: "General",
  user_type: :super_user,
  role: :admin,
  status: :active
)

puts "Creando materias..."
math = Subject.create!(name: "Matemáticas", description: "Números y operaciones", icon_color: "bg-blue-500", is_active: true)
science = Subject.create!(name: "Ciencias", description: "El mundo natural", icon_color: "bg-green-500", is_active: true)

puts "Creando cursos..."
math_course = Course.create!(name: "Matemáticas Básicas G1", description: "Grupo matutino", subject: math, user: teacher)
science_course = Course.create!(name: "Física Intro", description: "Introducción a física", subject: science, user: teacher)

puts "Creando inscripciones..."
Enrollment.create!(user: student, course: math_course)
Enrollment.create!(user: student, course: science_course)

puts "Creando lecciones..."
lesson1 = Lesson.create!(title: "Ecuaciones Lineales", description: "Introducción a ecuaciones", course: math_course)
lesson2 = Lesson.create!(title: "El Sistema Solar", description: "Planetas", course: science_course)

puts "Creando actividades..."
Activity.create!(title: "Ejercicios de Álgebra", status: 1, deadline: 2.days.from_now, score: nil, lesson: lesson1)
Activity.create!(title: "Proyecto Final", status: 2, deadline: 1.day.ago, score: "10/10", lesson: lesson2)

puts "Seed completado."
