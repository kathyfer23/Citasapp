import 'package:dio/dio.dart';
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
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error al crear cita';
      return {'success': false, 'message': msg};
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
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error al actualizar cita';
      return {'success': false, 'message': msg};
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

  Future<Map<String, dynamic>> sendWhatsAppReminder(String appointmentId) async {
    try {
      final response = await _api.post(
        '${ApiConfig.reminders}/$appointmentId/whatsapp',
      );

      if (response.data['success']) {
        return {'success': true};
      }

      return {'success': false, 'message': response.data['message']};
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error al enviar WhatsApp';
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Error al enviar WhatsApp'};
    }
  }

  Future<Map<String, dynamic>> saveTranscription(String id, String text) async {
    try {
      final response = await _api.post(
        '${ApiConfig.appointments}/$id/transcription',
        data: {'transcription': text},
      );

      if (response.data['success']) {
        return {
          'success': true,
          'appointment': Appointment.fromJson(response.data['data']),
        };
      }

      return {'success': false, 'message': response.data['message']};
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error al guardar transcripción';
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Error al guardar transcripción'};
    }
  }

  Future<Map<String, dynamic>> generateSummary(String id, {String? transcription}) async {
    try {
      final response = await _api.post(
        '${ApiConfig.appointments}/$id/summarize',
        data: transcription != null ? {'transcription': transcription} : null,
      );

      if (response.data['success']) {
        return {
          'success': true,
          'appointment': Appointment.fromJson(response.data['data']),
        };
      }

      return {'success': false, 'message': response.data['message']};
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error al generar resumen';
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Error al generar resumen'};
    }
  }
}
