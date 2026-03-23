import 'package:dio/dio.dart';
import 'dart:typed_data';
import '../models/models.dart';

class ReportService {
  // IMPORTANT: Replace this with your computer's IP address if testing on a real device
  static const String baseUrl = 'http://localhost:8000';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
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
      Map<String, dynamic> data = {
        'title': title,
        'descriptionText': description,
        'categoryId': categoryId,
        'location': location,
      };

      if (fileBytesList != null && fileNamesList != null) {
        List<MultipartFile> multipartFiles = [];
        for (int i = 0; i < fileBytesList.length; i++) {
          multipartFiles.add(
            MultipartFile.fromBytes(
              fileBytesList[i],
              filename: fileNamesList[i],
            ),
          );
        }
        data['files'] = multipartFiles;
      }

      FormData formData = FormData.fromMap(data, ListFormat.multiCompatible);

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

  Future<String> transcribeVoice(Uint8List audioBytes, String fileName, String token) async {
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
