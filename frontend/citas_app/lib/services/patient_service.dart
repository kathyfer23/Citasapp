import '../config/api_config.dart';
import '../models/patient_model.dart';
import 'api_service.dart';

class PatientService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getPatients({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.get(
        ApiConfig.patients,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success']) {
        final List<Patient> patients = (response.data['data'] as List)
            .map((json) => Patient.fromJson(json))
            .toList();
        
        return {
          'success': true,
          'patients': patients,
          'pagination': response.data['pagination'],
        };
      }
      
      return {'success': false, 'message': response.data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Error al obtener pacientes'};
    }
  }

  Future<Map<String, dynamic>> getPatient(String id) async {
    try {
      final response = await _api.get('${ApiConfig.patients}/$id');

      if (response.data['success']) {
        return {
          'success': true,
          'patient': Patient.fromJson(response.data['data']),
        };
      }
      
      return {'success': false, 'message': response.data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Error al obtener paciente'};
    }
  }

  Future<Map<String, dynamic>> createPatient(Patient patient) async {
    try {
      final response = await _api.post(
        ApiConfig.patients,
        data: patient.toJson(),
      );

      if (response.data['success']) {
        return {
          'success': true,
          'patient': Patient.fromJson(response.data['data']),
        };
      }
      
      return {'success': false, 'message': response.data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Error al crear paciente'};
    }
  }

  Future<Map<String, dynamic>> updatePatient(String id, Patient patient) async {
    try {
      final response = await _api.put(
        '${ApiConfig.patients}/$id',
        data: patient.toJson(),
      );

      if (response.data['success']) {
        return {
          'success': true,
          'patient': Patient.fromJson(response.data['data']),
        };
      }
      
      return {'success': false, 'message': response.data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Error al actualizar paciente'};
    }
  }

  Future<Map<String, dynamic>> deletePatient(String id) async {
    try {
      final response = await _api.delete('${ApiConfig.patients}/$id');

      if (response.data['success']) {
        return {'success': true};
      }
      
      return {'success': false, 'message': response.data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Error al eliminar paciente'};
    }
  }
}
