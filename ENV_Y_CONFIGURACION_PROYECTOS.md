# Documentación Completa de Variables de Entorno y Accesos

Este archivo contiene la documentación centralizada de todas las variables de entorno (`.env`), configuraciones de despliegue (Neon + Render) y credenciales de acceso para el proyecto **MaraPlus**.

---

## 1. Repositorios de GitHub

- **MaraPlus Repo**: `https://github.com/jesusenrique22/maraapp` (Rama `main`)

---

## 2. Variables de Entorno del Backend (`backend-nestjs/.env`)

### Entorno Local (Docker PostgreSQL)
Ubicación del archivo: [`backend-nestjs/.env`](file:///Users/smart/mara-app/backend-nestjs/.env)

```env
# Conexión a Base de Datos PostgreSQL local en Docker (Puerto 5433)
DATABASE_URL="postgresql://maraplus:maraplus_dev@localhost:5433/maraplus?schema=public"
DIRECT_URL="postgresql://maraplus:maraplus_dev@localhost:5433/maraplus?schema=public"

# Puerto donde escucha la API NestJS
PORT=3010

# URL pública de la API
PUBLIC_API_URL="http://127.0.0.1:3010"

# Seguridad y Tokens JWT
JWT_SECRET="maraplus-dev-secret-cambiar-en-produccion"
JWT_EXPIRES_IN="7d"

# Credenciales por defecto del Super Administrador
ADMIN_EMAIL="admin@maraplus.com"
ADMIN_PASSWORD="Admin123!"

# Integración con Google Gemini AI (AI Studio)
# Clave principal para el chat / asistente
GEMINI_API_KEY=""
# Clave dedicada para el escáner visual de recetas médicas
GEMINI_SCAN_API_KEY=""
GEMINI_MODEL="gemini-2.0-flash"
GEMINI_SCAN_MODEL="gemini-2.0-flash-lite"

# Clave opcional de RapidAPI para precios reales de bebidas
RAPIDAPI_KEY=""
```

---

## 3. Bases de Datos Cloud en Neon (Proyecto: smart-medic)

En tu cuenta de **Neon**, la base de datos principal para MaraPlus está configurada sobre el cluster `smart-medic`:

### Base de Datos para MaraPlus (`maraplus`)
- **DATABASE_URL**: `postgresql://neondb_owner:npg_6otjSrwAy8hs@ep-small-fire-atder57k.c-9.us-east-1.aws.neon.tech/maraplus?sslmode=require`
- **DIRECT_URL**: `postgresql://neondb_owner:npg_6otjSrwAy8hs@ep-small-fire-atder57k.c-9.us-east-1.aws.neon.tech/maraplus?sslmode=require`
- **Admin**: `admin@maraplus.com` / `Admin123!`
- **Médicos**: `doctor@maraplus.com`, `doctor2@maraplus.com`, `doctor3@maraplus.com`
- **Paciente**: `patient@maraplus.com`

---

## 4. Despliegue en Render (Variables de Entorno)

En el Dashboard de **Render** (`Environment` tab del servicio API), debes ingresar estas variables según el proyecto:

### Para el servicio `maraplusapp-api` (MaraPlus):
| Variable | Valor |
|---|---|
| `DATABASE_URL` | `postgresql://neondb_owner:npg_6otjSrwAy8hs@ep-small-fire-atder57k.c-9.us-east-1.aws.neon.tech/maraplus?sslmode=require` |
| `DIRECT_URL` | `postgresql://neondb_owner:npg_6otjSrwAy8hs@ep-small-fire-atder57k.c-9.us-east-1.aws.neon.tech/maraplus?sslmode=require` |
| `ADMIN_EMAIL` | `admin@maraplus.com` |
| `ADMIN_PASSWORD` | `Admin123!` |
| `JWT_SECRET` | `maraplus-prod-secret-2026-key` |
| `GEMINI_MODEL` | `gemini-2.0-flash` |
| `GEMINI_SCAN_MODEL` | `gemini-2.0-flash-lite` |

---

## 5. Tabla de Accesos y Usuarios de Prueba

| Proyecto | Rol | Correo Electrónico | Contraseña | Descripción |
|---|---|---|---|---|
| **MaraPlus** | **SUPER ADMIN** | `admin@maraplus.com` | `Admin123!` | Admin MaraPlus |
| **MaraPlus** | **MÉDICO 1** | `doctor@maraplus.com` | `Doctor123!` | Dr. Juan Pérez (Cardiología) |
| **MaraPlus** | **MÉDICO 2** | `doctor2@maraplus.com` | `Doctor123!` | Dra. María González |
| **MaraPlus** | **MÉDICO 3** | `doctor3@maraplus.com` | `Doctor123!` | Dr. Roberto Silva |
| **MaraPlus** | **PACIENTE** | `patient@maraplus.com` | `Patient123!` | Carlos Mendoza |

---

## 6. Comandos Utilitarios Rápidos

### Alternar a BD Cloud MaraPlus en Local:
```bash
cp backend-nestjs/.env.neon backend-nestjs/.env
```

### Alternar a BD Local (Docker):
```bash
cp backend-nestjs/.env.example backend-nestjs/.env
```
