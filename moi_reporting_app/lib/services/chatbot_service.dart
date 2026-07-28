import 'package:dio/dio.dart';
import 'report_service.dart';

class ChatbotService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ReportService.baseUrl,
    connectTimeout: const Duration(seconds: 45000),
    receiveTimeout: const Duration(seconds: 45000),
  ));

  Future<String> sendQuery({
    required String query,
    required String token,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/chatbot/chat',
        data: {
          'query': query,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['answer'] ?? response.data['response'] ?? 'لم يتم إرجاع إجابة.';
      }
      throw Exception('أخفق الاتصال بنظام المستشار القانوني');
    } on DioException catch (e) {
      if (e.response != null) {
        final detail = e.response?.data['detail'] ?? e.response?.data['message'] ?? e.message;
        throw Exception('$detail');
      }
      throw Exception('تعذر الاتصال بالخادم: ${e.message}');
    } catch (e) {
      throw Exception('خطأ غير متوقع: $e');
    }
  }
}
