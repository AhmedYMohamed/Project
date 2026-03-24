import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class OfficerService {
  late final Dio _dio;

  OfficerService() {
    _dio = Dio(BaseOptions(
      baseUrl: AuthService.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add interceptor to attach token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _dio.get('/api/v1/admin/dashboard/hot/statuscount');
      return response.data['counts'] ?? {};
    } catch (e) {
      // Fallback if the endpoint fails
      return {'Submitted': 0, 'InProgress': 0, 'Resolved': 0};
    }
  }

  Future<List<dynamic>> getNearbyReports({double? latitude, double? longitude}) async {
    try {
      final queryParams = {
        'skip': 0,
        'limit': 50,
        'radius_deg': 0.1,
      };
      
      // Add officer's current location to the query if available
      if (latitude != null && longitude != null) {
        queryParams['latitude'] = latitude;
        queryParams['longitude'] = longitude;
      }
      
      final response = await _dio.get('/api/v1/officer/reports/nearby', queryParameters: queryParams);
      return response.data['reports'] ?? [];
    } catch (e) {
      if (e is DioException) {
        print('Error fetching nearby reports: \${e.response?.data}');
      }
      return [];
    }
  }

  Future<Map<String, dynamic>> getReportDetails(String reportId) async {
    try {
      final response = await _dio.get('/api/v1/reports/$reportId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateReportStatus(String reportId, String status, String note) async {
    try {
      await _dio.put('/api/v1/reports/$reportId/status', data: {
        'status': status,
        'officerNote': note,
      });
    } catch (e) {
      rethrow;
    }
  }
}
