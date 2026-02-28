import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/main/main_screen.dart';
import '../screens/patients/patients_screen.dart';
import '../screens/patients/patient_detail_screen.dart';
import '../screens/patients/patient_form_screen.dart';
import '../screens/appointments/appointment_form_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/main/profile_screen.dart';
import '../screens/main/reports_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String patients = '/patients';
  static const String patientDetail = '/patients/detail';
  static const String patientForm = '/patients/form';
  static const String appointmentForm = '/appointments/form';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String reports = '/reports';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _buildRoute(const LoginScreen());
      case register:
        return _buildRoute(const RegisterScreen());
      case dashboard:
        return _buildRoute(const MainScreen());
      case patients:
        return _buildRoute(const PatientsScreen());
      case patientDetail:
        final patientId = settings.arguments as String;
        return _buildRoute(PatientDetailScreen(patientId: patientId));
      case patientForm:
        final patientId = settings.arguments as String?;
        return _buildRoute(PatientFormScreen(patientId: patientId));
      case appointmentForm:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(AppointmentFormScreen(
          appointmentId: args?['appointmentId'],
          preselectedPatientId: args?['patientId'],
          preselectedDate: args?['date'],
        ));
      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen());
      case profile:
        return _buildRoute(const ProfileScreen());
      case reports:
        return _buildRoute(const ReportsScreen());
      default:
        return _buildRoute(const LoginScreen());
    }
  }

  static PageRouteBuilder _buildRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
