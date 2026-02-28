import '../config/api_config.dart';
import '../models/appointment_model.dart';
import 'api_service.dart';

class AppointmentService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getAppointments({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? patientId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _api.get(
        ApiConfig.appointments,
        queryParameters: {
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
          if (status != null) 'status': status,
          if (patientId != null) 'patientId': patientId,
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success']) {
        final List<Appointment> appointments = (response.data['data'] as List)
            .map((json) => Appointment.fromJson(json))
            .toList();
        
        return {
          'success': true,
          'appointments': appointments,
          'pagination': response.data['pagination'],
        };
      }
      
      return {'success': false, 'message': response.data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Error al obtener citas'};
    }
  }

  Future<Map<String, dynamic>> getAppointment(String id) async {
    try {
      final response = await _api.get('${ApiConfig.appointments}/$id');

      if (response.data['success']) {
        return {
          'success': true,
          'appointment': Appointment.fromJson(response.data['data']),
        };
      }
      
      return {'success': false, 'message': response.data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Error al obtener cita'};
    }
  }

  Future<Map<String, dynamic>> createAppointment(Appointment appointment) async {
    try {
      final response = await _api.post(
        ApiConfig.appointments,
        data: appointment.toJson(),
      );

      if (response.data['success']) {
        return {
          'success': true,
          'appointment': Appointment.fromJson(response.data['data']),
        };
      }
      
      return {'success': false, 'message': response.data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Error al crear cita'};
    }
  }

  Future<Map<String, dynamic>> updateAppointment(
    String id, 
    Appointment appointment,
  ) async {
    try {
      final response = await _api.put(
        '${ApiConfig.appointments}/$id',
        data: appointment.toJson(),
      );

      if (response.data['success']) {
        return {
          'success': true,
          'appointment': Appointment.fromJson(response.data['data']),
        };
      }
      
      return {'success': false, 'message': response.data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Error al actualizar cita'};
    }
  }

  Future<Map<String, dynamic>> updateStatus(String id, String status) async {
    try {
      final response = await _api.patch(
        '${ApiConfig.appointments}/$id/status',
        data: {'status': status},
      );

      if (response.data['success']) {
        return {
          'success': true,
          'appointment': Appointment.fromJson(response.data['data']),
        };
      }
      
      return {'success': false, 'message': response.data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Error al actualizar estado'};
    }
  }

  Future<Map<String, dynamic>> deleteAppointment(String id) async {
    try {
      final response = await _api.delete('${ApiConfig.appointments}/$id');

      if (response.data['success']) {
        return {'success': true};
      }
      
      return {'success': false, 'message': response.data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Error al eliminar cita'};
    }
  }

  Future<Map<String, dynamic>> sendReminder(String appointmentId) async {
    try {
      final response = await _api.post(
        '${ApiConfig.reminders}/$appointmentId',
      );

      if (response.data['success']) {
        return {'success': true};
      }
      
      return {'success': false, 'message': response.data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Error al enviar recordatorio'};
    }
  }
}
