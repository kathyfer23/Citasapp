# Citas App - Frontend Flutter

Aplicación móvil y web para gestión de citas médicas.

## Características

- Login y registro de profesionales
- Dashboard con calendario interactivo
- Gestión de pacientes (CRUD)
- Gestión de citas
- Envío de recordatorios por correo
- Identificación de pacientes nuevos vs existentes

## Requisitos

- Flutter SDK 3.0+
- Dart 3.0+

## Instalación

1. Instalar dependencias:
```bash
flutter pub get
```

2. Configurar la URL del backend:
   - Editar `lib/config/api_config.dart`
   - Cambiar `baseUrl` a la URL de tu backend

3. Ejecutar en desarrollo:
```bash
# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

## Estructura del proyecto

```
lib/
├── config/           # Configuración (tema, rutas, API)
├── models/           # Modelos de datos
├── providers/        # State management (Provider)
├── screens/          # Pantallas de la aplicación
│   ├── auth/         # Login y registro
│   ├── dashboard/    # Dashboard principal
│   ├── patients/     # Gestión de pacientes
│   ├── appointments/ # Gestión de citas
│   └── settings/     # Configuración
├── services/         # Servicios de API
├── widgets/          # Widgets reutilizables
└── main.dart         # Punto de entrada
```

## Compilar para producción

```bash
# Web
flutter build web

# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS
flutter build ios
```
