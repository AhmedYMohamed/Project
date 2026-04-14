import 'package:dio/dio.dart';
import 'dart:typed_data';
import '../models/models.dart';

class ReportService {
  // IMPORTANT: Replace this with your computer's IP address if testing on a real device
  static const String baseUrl =
      'https://special-trout-q7v4g6676g5vc6794-8000.app.github.dev';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10000),
    receiveTimeout: const Duration(seconds: 10000),
  ));

  Future<Response> createReport({
    required String title,
    required String description,
    required String categoryId,
    required String token,
    required String location,
    List<Uint8List>? fileBytesList,
    List<String>? fileNamesList,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'title': title,
        'descriptionText': description,
        'categoryId': categoryId,
        'location': location,
      });

      if (fileBytesList != null && fileNamesList != null) {
        for (int i = 0; i < fileBytesList.length; i++) {
          formData.files.add(MapEntry(
            'files',
            MultipartFile.fromBytes(
              fileBytesList[i],
              filename: fileNamesList[i],
            ),
          ));
        }
      }

      return await _dio.post(
        '/api/v1/reports/',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ReportModel>> getUserReports(String token, String userId) async {
    try {
      final response = await _dio.get(
        '/api/v1/reports/user/$userId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      // The backend returns a ReportListResponse object with a 'reports' field
      final List reportsJson = response.data['reports'] ?? [];

      return reportsJson.map((json) => ReportModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> transcribeVoice(
      Uint8List audioBytes, String fileName, String token) async {
    try {
      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          audioBytes,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/api/v1/voice/transcribe',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.data['text'] ?? '';
    } catch (e) {
      print('DEBUG: Transcribe error: $e');
      rethrow;
    }
  }
}
