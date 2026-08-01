import 'package:dio/dio.dart';
import '../models/notification_model.dart';
import 'auth_service.dart';

class NotificationCenterService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AuthService.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<List<NotificationModel>> getNotifications(String token) async {
    try {
      final response = await _dio.get(
        '/api/v1/notifications/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final List data = response.data ?? [];
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getUnreadCount(String token) async {
    try {
      final response = await _dio.get(
        '/api/v1/notifications/unread-count',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data['unreadCount'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> markAsRead(String token, String notificationId) async {
    try {
      await _dio.put(
        '/api/v1/notifications/$notificationId/read',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (_) {}
  }

  Future<void> markAllAsRead(String token) async {
    try {
      await _dio.put(
        '/api/v1/notifications/read-all',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (_) {}
  }
}
