import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // IMPORTANT: Replace with your computer's IP address if testing on a real device
  static const String baseUrl = 'https://cuddly-dollop-97654ww7wvr6cg9q-8000.app.github.dev/';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      final response = await _dio.post('/api/v1/auth/register', data: {
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'role': 'citizen',
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, String>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Create form data for OAuth2 login
      FormData formData = FormData.fromMap({
        'username': email,
        'password': password,
      });

      final response = await _dio.post(
        '/api/v1/auth/login',
        data: formData,
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      final token = response.data['access_token'];
      final userId = response.data['user_id'];

      // Save token and userId locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      await prefs.setString('user_id', userId);

      return {
        'token': token,
        'userId': userId,
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }
}
