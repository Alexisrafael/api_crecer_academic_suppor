# 🎓 Crecer Academic Support — API Backend (Rails 8 API)

Backend de nivel de producción desarrollado en **Ruby 3.3.3** y **Ruby on Rails 8.0** en modo API (`--api`), diseñado para servir a la arquitectura dual de cliente (Web Desktop y App Móvil). Incorpora autenticación robusta JWT, prevención estricta de consultas N+1, gestión de colas con **Solid Queue**, caché con **Solid Cache**, subida de archivos con **Active Storage** y soporte de mensajería asíncrona.

---

## 🏗️ 1. Arquitectura y Stack Tecnológico

| Componente | Tecnología | Descripción |
| :--- | :--- | :--- |
| **Lenguaje** | Ruby `3.3.3` | Entorno de ejecución con alto rendimiento y tipado dinámico seguro. |
| **Framework** | Rails `8.0.x` API | Modo API puro (`config.api_only = true`), optimizado para JSON liviano. |
| **Base de Datos** | PostgreSQL `>= 14` | Soporte para campos relacionales complejos y columnas `jsonb` para actividades interactivas. |
| **Autenticación** | JWT (JSON Web Tokens) | Esquema dual: Bearer Token en cabecera `Authorization` + Cookies `HttpOnly` para Web. |
| **Background Jobs** | Solid Queue | Motor de colas respaldado por base de datos (sin dependencia obligatoria de Redis). |
| **Caché y Almacenamiento** | Solid Cache | Almacén de caché duradero respaldado en PostgreSQL. |
| **Archivos / Media** | Active Storage | Gestión de avatares y multimedia de lecciones (local / S3 / Cloudinary). |
| **Servidor Web** | Puma + Thruster | Servidor HTTP de producción con aceleración de activos y compresión HTTP/2. |

---

## 🔒 2. Seguridad y Arquitectura de Autenticación

El sistema implementa una arquitectura de autenticación **Stateless y Dual** diseñada para operar fluidamente tanto en navegadores web (desktop) como en aplicaciones móviles o PWA:

### Flujo de Tokens
1. **Access Token (`access_token`)**:
   - Algoritmo: `HS256`.
   - Firma: Generada mediante `Rails.application.secret_key_base` (compatible con `ENV['SECRET_KEY_BASE']` y credenciales cifradas).
   - Duración: **15 a 60 minutos**.
   - Transporte: Entregado en el cuerpo JSON de respuesta y en cookie `HttpOnly`, `SameSite=Lax` (o `None` en producción cross-origin con SSL).
2. **Refresh Token (`refresh_token`)**:
   - Duración: **30 días** (`30.days.from_now`).
   - Transporte: Enviado en cookie `HttpOnly` y en el JSON (`tokens[:refresh_token]`), permitiendo a clientes móviles almacenarlo en almacenamiento seguro (Keystore/Keychain/SecureStore).
3. **Exclusión de Datos Sensibles**:
   - El modelo `User` sobreescribe `as_json` para excluir terminantemente el hash `password_digest` en todas las respuestas JSON del sistema.
4. **Endpoint de Verificación de Sesión**:
   - `GET /api/v1/auth/me`: Permite a los clientes validar instantáneamente la vigencia de la sesión en el servidor durante el arranque o recarga de la aplicación.

---

## 📡 3. Especificación de Endpoints (Contratos API v1)

Todas las rutas públicas y protegidas se encuentran bajo el espacio de nombres `/api/v1`.

### 🔐 Autenticación (`/api/v1/auth`)

| Método | Ruta | Acceso | Descripción | Payload / Parámetros |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/auth/register` | Público | Registra un usuario y retorna tokens | `{ email, password, password_confirmation, first_name, last_name, register_as_tutor? }` |
| `POST` | `/auth/login` | Público | Inicia sesión y genera tokens | `{ email, password }` |
| `POST` | `/auth/refresh` | Público | Refresca el par de tokens | Cookie `refresh_token`, o Body `{ refresh_token }`, o Header `X-Refresh-Token` |
| `DELETE` | `/auth/logout` | Protegido | Elimina cookies de sesión | Ninguno |
| `GET` | `/auth/me` | Protegido | Retorna perfil del usuario autenticado | Cabecera `Authorization: Bearer <token>` o Cookie |
| `PUT` | `/auth/update_profile`| Protegido | Actualiza nombres y avatar | `multipart/form-data`: `first_name`, `last_name`, `avatar` (archivo) |

### 📊 Dashboard y Progreso (`/api/v1`)

| Método | Ruta | Acceso | Descripción | Respuesta Clave |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/dashboard` | Alumno/Tutor | Métricas, trofeos, lecciones y progreso (Cero N+1) | `{ user, total_trophies, activities, last_video, subjects_progress }` |
| `GET` | `/dashboard/history` | Alumno | Historial agrupado de actividades y notas | `{ total_trophies, history_by_subject }` |
| `POST` | `/progress` | Alumno | Registra avance de lección o juego | `{ lesson_id?, activity_id?, progress_percent, is_completed, last_video_position? }` |

### 📚 Materias y Cursos (`/api/v1`)

| Método | Ruta | Acceso | Descripción |
| :--- | :--- | :--- | :--- |
| `GET` | `/subjects` | Autenticado | Lista materias activas. |
| `GET` | `/subjects/:id` | Autenticado | Detalle de una materia específica. |
| `POST` | `/subjects` | Solo Admin | Crea una nueva materia (`name`, `description`, `icon_color`, `is_active`). |
| `PUT` | `/subjects/:id` | Solo Admin | Actualiza una materia. |
| `DELETE` | `/subjects/:id` | Solo Admin | Elimina una materia. |
| `GET` | `/subjects/:subject_id/teachers` | Autenticado | Lista profesores con cursos en la materia. |
| `GET` | `/subjects/:subject_id/teachers/:teacher_id/classes` | Autenticado | Cursos/grupos del profesor en la materia. |
| `POST` | `/subjects/:subject_id/teachers/:teacher_id/enroll` | Estudiante | Inscribe al estudiante en el curso del profesor. |
| `GET` | `/subjects/:subject_id/my_classes` | Profesor/Admin | Lista cursos dictados por el profesor en la materia. |
| `POST` | `/subjects/:subject_id/classes` | Profesor/Admin | Crea un nuevo curso/grupo. |

### 📖 Lecciones y Actividades/Juegos (`/api/v1`)

| Método | Ruta | Acceso | Descripción |
| :--- | :--- | :--- | :--- |
| `GET` | `/classes/:id` | Autenticado | Detalle del curso y estado de inscripción (`is_enrolled`). |
| `GET` | `/classes/:class_id/lessons` | Autenticado | Lecciones del curso con actividades y estados completados. |
| `POST` | `/classes/:class_id/lessons` | Profesor/Admin | Crea una lección (`title`, `description`, `video_url`). |
| `PUT` | `/lessons/:id` | Profesor/Admin | Actualiza una lección. |
| `DELETE` | `/lessons/:id` | Profesor/Admin | Elimina una lección. |
| `POST` | `/classes/:class_id/activities` | Profesor/Admin | Crea un juego/actividad (`title`, `activity_type`, `content`, `lesson_id`). |
| `DELETE` | `/activities/:id` | Profesor/Admin | Elimina un juego/actividad. |

---

## ⚙️ 4. Variables de Entorno (.env)

Copia el archivo de ejemplo para configurar tu entorno:

```bash
cp .env.example .env
```

Variables indispensables:

```env
# Entorno y Secretos
RAILS_ENV=production
SECRET_KEY_BASE=tu_secreto_generado_con_rails_secret
PORT=3000
RAILS_MAX_THREADS=5

# Base de Datos PostgreSQL
DATABASE_URL=postgres://usuario:password@host_postgres:5432/crecer_production

# CORS (Orígenes Autorizados para Web y Móvil)
FRONTEND_URL=https://tu-dominio-frontend.com
ALLOWED_ORIGINS=https://tu-dominio-frontend.com,https://tu-app-movil.com
MOVIL_URL=https://m.tu-dominio.com

# Almacenamiento de Archivos (Active Storage)
ACTIVE_STORAGE_SERVICE=local # En producción en contenedores usar amazon, cloudinary o gcs
```

---

## 🚀 5. Despliegue a Producción

### Opción A: Despliegue con Docker (Recomendada)

El proyecto incluye un `Dockerfile` optimizado multi-stage con **Ruby 3.3.3-slim** y aceleración mediante **Thruster**:

1. **Construir la imagen:**
   ```bash
   docker build -t api_crecer_academic_suppor .
   ```

2. **Ejecutar el contenedor:**
   ```bash
   docker run -d \
     -p 80:80 \
     -e RAILS_ENV=production \
     -e SECRET_KEY_BASE="genera_un_secreto_robusto" \
     -e DATABASE_URL="postgres://user:pass@db-host:5432/crecer_prod" \
     -e FRONTEND_URL="https://tu-frontend.com" \
     --name crecer_api \
     api_crecer_academic_suppor
   ```

### Opción B: Despliegue en Plataformas Cloud (Render, Railway, Fly.io, Heroku)

1. **Crear una base de datos PostgreSQL** administrada.
2. **Configurar las variables de entorno**: Asignar `DATABASE_URL`, `SECRET_KEY_BASE`, `RAILS_ENV=production`, `FRONTEND_URL` y `ALLOWED_ORIGINS`.
3. **Comando de inicialización de Base de Datos**:
   ```bash
   bin/rails db:prepare db:seed
   ```
4. **Comando de arranque**:
   ```bash
   ./bin/thrust ./bin/rails server
   ```

### Opción C: Despliegue con Kamal en Servidor VPS

El proyecto cuenta con `config/deploy.yml` configurado para desplegar mediante Kamal con cero downtime y proxy Traefik integrado:

```bash
kamal setup
kamal deploy
```

---

## 🧪 6. Pruebas y Validación

Para ejecutar las validaciones y verificar que todo el código esté libre de errores sintácticos o N+1:

```bash
# Verificar sintaxis de controladores y modelos
find app/ -name "*.rb" -exec ruby -c {} +

# Ejecutar suite de pruebas de Rails
bin/rails test
```

---

## 👨‍💻 7. Cuentas de Acceso Semilla (Seeds de Prueba)

Al ejecutar `bin/rails db:seed` se generan las siguientes credenciales para pruebas:

- **Estudiante**: `estudiante@ejemplo.com` / `password123`
- **Profesor**: `profesor@ejemplo.com` / `password123`
- **Administrador**: `admin@ejemplo.com` / `password123`
