import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/models.dart';

class ReportService {
  // IMPORTANT: Replace this with your computer's IP address if testing on a real device
  static const String baseUrl =
      'https://moi-app-v2-c0bxdabgf7eteaab.israelcentral-01.azurewebsites.net/';

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
    bool sendToLawyer = false,
    List<Uint8List>? fileBytesList,
    List<String>? fileNamesList,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'title': title,
        'descriptionText': description,
        'categoryId': categoryId,
        'location': location,
        'sendToLawyer': sendToLawyer.toString(),
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

  Future<List<ReportModel>> getUserReports(String token, String userId, {bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'cached_user_reports_$userId';

    if (!forceRefresh) {
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        try {
          final List decoded = jsonDecode(cachedData);
          return decoded.map((json) => ReportModel.fromJson(json)).toList();
        } catch (_) {}
      }
    }

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

      // Save to local cache
      await prefs.setString(cacheKey, jsonEncode(reportsJson));

      return reportsJson.map((json) => ReportModel.fromJson(json)).toList();
    } catch (e) {
      // Fallback to cache on error if not already returned
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        try {
          final List decoded = jsonDecode(cachedData);
          return decoded.map((json) => ReportModel.fromJson(json)).toList();
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<ReportModel> getReportById(String token, String reportId) async {
    try {
      final response = await _dio.get(
        '/api/v1/reports/$reportId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      debugPrint('=== CITIZEN GET REPORT RESPONSE ===');
      debugPrint('Report JSON response: ${response.data}');
      return ReportModel.fromJson(response.data);
    } catch (e) {
      debugPrint('Citizen getReportById error: $e');
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

  Future<Response> updateReport({
    required String reportId,
    required String token,
    required String title,
    required String description,
    required String location,
    required String categoryId,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'title': title,
        'descriptionText': description,
        'location': location,
        'categoryId': categoryId,
      });

      return await _dio.put(
        '/api/v1/reports/$reportId',
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
}
