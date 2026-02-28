# Citas App SaaS

Sistema de gestión de citas para profesionales de la salud (doctores, psicólogos, etc.)

## Arquitectura

```
Citasapp/
├── backend/          # API REST (Node.js + Express + Prisma)
└── frontend/         # App móvil y web (Flutter)
    └── citas_app/
```

## Características

- Autenticación de profesionales (registro/login)
- Gestión de pacientes (nuevo vs existente)
- Calendario de citas con vista mensual/semanal
- Envío de recordatorios por correo (automático y manual)
- Dashboard con estadísticas
- Soporte para web, Android e iOS

## Requisitos

### Backend
- Node.js 18+
- PostgreSQL 14+

### Frontend
- Flutter SDK 3.0+

## Instalación

### 1. Base de datos

Crear una base de datos PostgreSQL llamada `citasapp`

### 2. Backend

```bash
cd backend

# Instalar dependencias
npm install

# Configurar variables de entorno
copy env.example .env
# Editar .env con tus credenciales

# Ejecutar migraciones
npm run prisma:migrate

# Generar cliente Prisma
npm run prisma:generate

# Iniciar servidor
npm run dev
```

### 3. Frontend

```bash
cd frontend/citas_app

# Instalar dependencias
flutter pub get

# Configurar URL del backend en lib/config/api_config.dart

# Ejecutar
flutter run -d chrome    # Web
flutter run -d android   # Android
flutter run -d ios       # iOS
```

## Endpoints API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | /api/auth/register | Registro |
| POST | /api/auth/login | Login |
| GET | /api/patients | Listar pacientes |
| POST | /api/patients | Crear paciente |
| GET | /api/appointments | Listar citas |
| POST | /api/appointments | Crear cita |
| POST | /api/reminders/:id | Enviar recordatorio |

## Tecnologías

- **Backend**: Node.js, Express, Prisma, PostgreSQL, JWT, Nodemailer
- **Frontend**: Flutter, Provider, Dio, Table Calendar
