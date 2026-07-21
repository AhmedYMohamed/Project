import 'package:flutter/foundation.dart';

class UserModel {
  final String userId;
  final String? email;
  final String? phoneNumber;
  final String role;
  final bool isAnonymous;

  UserModel({
    required this.userId,
    this.email,
    this.phoneNumber,
    required this.role,
    this.isAnonymous = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      role: json['role'] ?? 'citizen',
      isAnonymous: json['isAnonymous'] ?? false,
    );
  }
}

class ReportModel {
  final String reportId;
  final String title;
  final String descriptionText;
  final String status;
  final String categoryId;
  final String? location;
  final String? officerNote;
  final DateTime createdAt;
  final List<AttachmentModel> attachments;

  ReportModel({
    required this.reportId,
    required this.title,
    required this.descriptionText,
    required this.status,
    required this.categoryId,
    this.location,
    this.officerNote,
    required this.createdAt,
    required this.attachments,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final note = (json['officerNote'] ?? json['officer_note'] ?? json['notes']) as String?;
    debugPrint('=== ReportModel.fromJson === officerNote extracted: "$note" (raw officerNote=${json['officerNote']}, officer_note=${json['officer_note']}, notes=${json['notes']})');
    return ReportModel(
      reportId: json['reportId'] ?? json['report_id'] ?? '',
      title: json['title'] ?? '',
      descriptionText: json['descriptionText'] ?? json['description_text'] ?? '',
      status: json['status'] ?? 'Submitted',
      categoryId: json['categoryId'] ?? json['category_id'] ?? '',
      location: (json['location'] ?? json['locationRaw']) as String?,
      officerNote: note,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      attachments: (json['attachments'] as List? ?? [])
          .map((a) => AttachmentModel.fromJson(a))
          .toList(),
    );
  }
}

class AttachmentModel {
  final String attachmentId;
  final String blobStorageUri;
  final String? downloadUrl;
  final String fileType;

  AttachmentModel({
    required this.attachmentId,
    required this.blobStorageUri,
    this.downloadUrl,
    required this.fileType,
  });

  /// Primary URL to use for rendering/downloading attachments.
  /// Prefers SAS token URL (downloadUrl) if available, falling back to blobStorageUri.
  String get displayUrl => (downloadUrl != null && downloadUrl!.trim().isNotEmpty)
      ? downloadUrl!
      : blobStorageUri;

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      attachmentId: json['attachmentId'] ?? '',
      blobStorageUri: json['blobStorageUri'] ?? '',
      downloadUrl: json['downloadUrl'] as String?,
      fileType: json['fileType'] ?? 'document',
    );
  }
}
