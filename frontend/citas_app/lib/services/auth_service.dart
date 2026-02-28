import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _api.post(
        ApiConfig.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.data['success']) {
        final token = response.data['data']['token'];
        await _api.setToken(token);
        
        return {
          'success': true,
          'user': User.fromJson(response.data['data']['user']),
        };
      }
      
      return {
        'success': false,
        'message': response.data['message'] ?? 'Error al iniciar sesión',
      };
    } catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String profession,
    String? phone,
  }) async {
    try {
      final response = await _api.post(
        ApiConfig.register,
        data: {
          'email': email,
          'password': password,
          'name': name,
          'profession': profession,
          'phone': phone,
        },
      );

      if (response.data['success']) {
        final token = response.data['data']['token'];
        await _api.setToken(token);
        
        return {
          'success': true,
          'user': User.fromJson(response.data['data']['user']),
        };
      }
      
      return {
        'success': false,
        'message': response.data['message'] ?? 'Error al registrar',
      };
    } catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
  }

  Future<bool> isAuthenticated() async {
    final token = await _api.getToken();
    return token != null;
  }

  String _getErrorMessage(dynamic error) {
    if (error.response?.data != null) {
      return error.response.data['message'] ?? 'Error de conexión';
    }
    return 'Error de conexión con el servidor';
  }
}
