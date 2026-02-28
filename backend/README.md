# Backend - Citas App SaaS

API REST para la aplicación de gestión de citas médicas.

## Tecnologías

- Node.js + Express
- PostgreSQL + Prisma ORM
- JWT para autenticación
- Nodemailer para envío de correos
- Node-cron para tareas programadas

## Instalación

1. Instalar dependencias:
```bash
npm install
```

2. Configurar variables de entorno:
```bash
# Copiar el archivo de ejemplo
copy env.example .env
# Editar .env con tus credenciales
```

3. Configurar la base de datos PostgreSQL y actualizar DATABASE_URL en .env

4. Ejecutar migraciones de Prisma:
```bash
npm run prisma:migrate
```

5. Generar cliente de Prisma:
```bash
npm run prisma:generate
```

## Ejecución

Desarrollo:
```bash
npm run dev
```

Producción:
```bash
npm start
```

## Endpoints

### Autenticación
- POST `/api/auth/register` - Registro de profesional
- POST `/api/auth/login` - Inicio de sesión

### Pacientes
- GET `/api/patients` - Listar pacientes
- GET `/api/patients/:id` - Obtener paciente
- POST `/api/patients` - Crear paciente
- PUT `/api/patients/:id` - Actualizar paciente
- DELETE `/api/patients/:id` - Eliminar paciente

### Citas
- GET `/api/appointments` - Listar citas (con filtros)
- GET `/api/appointments/:id` - Obtener cita
- POST `/api/appointments` - Crear cita
- PUT `/api/appointments/:id` - Actualizar cita
- PATCH `/api/appointments/:id/status` - Cambiar estado
- DELETE `/api/appointments/:id` - Eliminar cita

### Recordatorios
- POST `/api/reminders/:appointmentId` - Enviar recordatorio manual
