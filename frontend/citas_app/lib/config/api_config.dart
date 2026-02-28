class ApiConfig {
  // Cambiar esta URL según el entorno
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Endpoints de autenticación
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  
  // Endpoints de pacientes
  static const String patients = '/patients';
  
  // Endpoints de citas
  static const String appointments = '/appointments';
  
  // Endpoints de recordatorios
  static const String reminders = '/reminders';
  
  // Timeout de conexión
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
