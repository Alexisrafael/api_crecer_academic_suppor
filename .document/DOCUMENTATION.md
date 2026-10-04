# Documentación del Backend (API) - Crecer Academic Support

## 🎯 ¿Para qué sirve?
Este proyecto sirve como el **Cerebro y Motor Central (Backend)** de la plataforma "Apoyo Escolar Crecer". Es una API RESTFul que se encarga de:
- Autenticar y gestionar a los usuarios (Estudiantes, Profesores, Administradores).
- Proveer y almacenar toda la lógica de negocio (Progreso de cursos, lecciones, trofeos ganados, cálculo de calificaciones).
- Guardar de manera segura los datos en la base de datos (PostgreSQL).
- Recibir, procesar y almacenar archivos físicos como fotos de perfil mediante ActiveStorage.

## ⚙️ ¿Qué hace?
- Expone "endpoints" (URL's) como `/api/v1/auth/login` o `/api/v1/dashboard` que son consumidos por el cliente web y móvil.
- Utiliza **JWT (JSON Web Tokens)** para manejar las sesiones de manera segura y escalable sin depender de cookies tradicionales bloqueantes.
- Calcula en tiempo real las estadísticas (porcentaje de completitud de cursos, validación del umbral de 60% para aprobar actividades).
- Gestiona roles, evitando que un estudiante modifique lecciones o que un profesor sin permisos elimine cursos enteros.

## 🛠️ Tecnologías Utilizadas
Este stack tecnológico está alineado a un estándar moderno de alto rendimiento:
- **Ruby:** 3.3.3
- **Framework:** Ruby on Rails 8.x (En modo API puro)
- **Base de Datos:** PostgreSQL
- **Manejo de Tareas Asíncronas (Jobs):** Solid Queue (nativo sin necesidad de Redis).
- **Manejo de Caché:** Solid Cache.
- **Autenticación:** Gema `jwt` con expiración escalonada.
- **Almacenamiento de Archivos:** ActiveStorage (Guardado en Disco Local / Nube).

---

## 🚀 ¿Cómo se debe hacer para correr el proyecto?

Para arrancar el motor de la API localmente en cualquier entorno de desarrollo, sigue estos pasos:

### 1. Pre-requisitos
Asegúrate de tener instalados:
- Ruby (3.3.3 recomendado)
- PostgreSQL corriendo localmente
- Bundler (`gem install bundler`)

### 2. Instalación
Abre la terminal en la carpeta raíz del backend (`api_crecer_academic_suppor`) y ejecuta:
```bash
# 1. Instalar todas las dependencias
bundle install

# 2. Crear la base de datos y correr las migraciones (estructuras de tablas)
rails db:create
rails db:migrate

# 3. (Opcional) Si existe un archivo de semillas, poblar la base de datos base
rails db:seed
```

### 3. Ejecución
Para levantar el servidor en el puerto 3000, ejecuta:
```bash
rails server -p 3000
```
> **Nota:** El servidor ahora está escuchando peticiones en `http://localhost:3000`. ¡Déjalo corriendo mientras trabajas con el frontend!
