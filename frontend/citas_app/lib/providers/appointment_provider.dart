import 'package:flutter/foundation.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

class AppointmentProvider with ChangeNotifier {
  final AppointmentService _appointmentService = AppointmentService();
  
  List<Appointment> _appointments = [];
  Appointment? _selectedAppointment;
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  List<Appointment> get appointments => _appointments;
  Appointment? get selectedAppointment => _selectedAppointment;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;

  // Obtener citas del día seleccionado
  List<Appointment> get appointmentsForSelectedDate {
    return _appointments.where((apt) {
      return apt.dateTime.year == _selectedDate.year &&
             apt.dateTime.month == _selectedDate.month &&
             apt.dateTime.day == _selectedDate.day;
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // Obtener citas de hoy
  List<Appointment> get todayAppointments {
    final now = DateTime.now();
    return _appointments.where((apt) {
      return apt.dateTime.year == now.year &&
             apt.dateTime.month == now.month &&
             apt.dateTime.day == now.day &&
             apt.status == AppointmentStatus.scheduled;
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // Obtener próximas citas
  List<Appointment> get upcomingAppointments {
    final now = DateTime.now();
    return _appointments.where((apt) {
      return apt.dateTime.isAfter(now) && 
             apt.status == AppointmentStatus.scheduled;
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // Mapa de citas por fecha para el calendario
  Map<DateTime, List<Appointment>> get appointmentsByDate {
    final Map<DateTime, List<Appointment>> map = {};
    for (var apt in _appointments) {
      final date = DateTime(
        apt.dateTime.year, 
        apt.dateTime.month, 
        apt.dateTime.day,
      );
      if (map[date] == null) {
        map[date] = [];
      }
      map[date]!.add(apt);
    }
    return map;
  }

  /// Obtener citas programadas para una fecha específica
  List<Appointment> getAppointmentsForDate(DateTime date) {
    return _appointments.where((apt) {
      return apt.dateTime.year == date.year &&
             apt.dateTime.month == date.month &&
             apt.dateTime.day == date.day &&
             apt.status == AppointmentStatus.scheduled;
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Verificar si un horario genera conflicto con citas existentes
  Appointment? checkConflict(DateTime dateTime, int duration, {String? excludeId}) {
    final endTime = dateTime.add(Duration(minutes: duration));
    for (final apt in _appointments) {
      if (apt.status != AppointmentStatus.scheduled) continue;
      if (excludeId != null && apt.id == excludeId) continue;
      if (dateTime.isBefore(apt.endTime) && endTime.isAfter(apt.dateTime)) {
        return apt;
      }
    }
    return null;
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> loadAppointments({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? patientId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Por defecto, cargar citas del mes actual
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month - 1, 1);
    final end = endDate ?? DateTime(now.year, now.month + 2, 0);

    final result = await _appointmentService.getAppointments(
      startDate: start,
      endDate: end,
      status: status,
      patientId: patientId,
    );

    _isLoading = false;

    if (result['success']) {
      _appointments = result['appointments'];
    } else {
      _error = result['message'];
    }

    notifyListeners();
  }

  Future<void> loadAppointment(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _appointmentService.getAppointment(id);

    _isLoading = false;

    if (result['success']) {
      _selectedAppointment = result['appointment'];
    } else {
      _error = result['message'];
    }

    notifyListeners();
  }

  Future<bool> createAppointment(Appointment appointment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _appointmentService.createAppointment(appointment);

    _isLoading = false;

    if (result['success']) {
      _appointments.add(result['appointment']);
      _appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAppointment(String id, Appointment appointment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _appointmentService.updateAppointment(id, appointment);

    _isLoading = false;

    if (result['success']) {
      final index = _appointments.indexWhere((a) => a.id == id);
      if (index != -1) {
        _appointments[index] = result['appointment'];
      }
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(String id, AppointmentStatus status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _appointmentService.updateStatus(id, status.name);

    _isLoading = false;

    if (result['success']) {
      final index = _appointments.indexWhere((a) => a.id == id);
      if (index != -1) {
        _appointments[index] = result['appointment'];
      }
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAppointment(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _appointmentService.deleteAppointment(id);

    _isLoading = false;

    if (result['success']) {
      _appointments.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendReminder(String appointmentId) async {
    final result = await _appointmentService.sendReminder(appointmentId);

    if (result['success']) {
      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(reminderSent: true);
        notifyListeners();
      }
      return true;
    } else {
      _error = result['message'];
      notifyListeners();
      return false;
    }
  }

  /// Obtiene el link wa.me del backend y marca como enviado localmente.
  /// Retorna la URL de WhatsApp o null si hay error.
  Future<String?> getWhatsAppLink(String appointmentId) async {
    final result = await _appointmentService.getWhatsAppLink(appointmentId);

    if (result['success']) {
      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(whatsappReminderSent: true);
        notifyListeners();
      }
      return result['whatsappUrl'] as String;
    } else {
      _error = result['message'];
      notifyListeners();
      return null;
    }
  }

  Future<bool> saveTranscription(String id, String text) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _appointmentService.saveTranscription(id, text);

    _isLoading = false;

    if (result['success']) {
      final updated = result['appointment'] as Appointment;
      final index = _appointments.indexWhere((a) => a.id == id);
      if (index != -1) {
        _appointments[index] = updated;
      }
      _selectedAppointment = updated;
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> generateSummary(String id, {String? transcription}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _appointmentService.generateSummary(id, transcription: transcription);

    _isLoading = false;

    if (result['success']) {
      final updated = result['appointment'] as Appointment;
      final index = _appointments.indexWhere((a) => a.id == id);
      if (index != -1) {
        _appointments[index] = updated;
      }
      _selectedAppointment = updated;
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      notifyListeners();
      return false;
    }
  }

  void clearSelectedAppointment() {
    _selectedAppointment = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
