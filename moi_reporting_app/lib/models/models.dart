import 'package:flutter/foundation.dart';

class UserModel {
  final String userId;
  final String? email;
  final String? phoneNumber;
  final String role;
  final bool isAnonymous;
  final String? lawyerId;
  final String? lawyerQrCode;
  final String? syndicateId;
  final String? digitalSignatureUrl;

  UserModel({
    required this.userId,
    this.email,
    this.phoneNumber,
    required this.role,
    this.isAnonymous = false,
    this.lawyerId,
    this.lawyerQrCode,
    this.syndicateId,
    this.digitalSignatureUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      role: json['role'] ?? 'citizen',
      isAnonymous: json['isAnonymous'] ?? false,
      lawyerId: json['lawyerId'] ?? json['lawyer_id'],
      lawyerQrCode: json['lawyerQrCode'] ?? json['lawyer_qr_code'],
      syndicateId: json['syndicateId'] ?? json['syndicate_id'],
      digitalSignatureUrl: json['digitalSignatureUrl'] ?? json['digital_signature_url'],
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
  final String? lawyerId;
  final String? lawyerSignature;
  final String? lawyerFeedback;
  final bool isUrgentEscalation;

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
    this.lawyerId,
    this.lawyerSignature,
    this.lawyerFeedback,
    this.isUrgentEscalation = false,
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
      lawyerId: json['lawyerId'] ?? json['lawyer_id'],
      lawyerSignature: json['lawyerSignature'] ?? json['lawyer_signature'],
      lawyerFeedback: json['lawyerFeedback'] ?? json['lawyer_feedback'],
      isUrgentEscalation: json['isUrgentEscalation'] ?? json['is_urgent_escalation'] ?? false,
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

class ReportMessageModel {
  final String messageId;
  final String reportId;
  final String senderId;
  final String senderRole;
  final String messageText;
  final DateTime createdAt;

  ReportMessageModel({
    required this.messageId,
    required this.reportId,
    required this.senderId,
    required this.senderRole,
    required this.messageText,
    required this.createdAt,
  });

  factory ReportMessageModel.fromJson(Map<String, dynamic> json) {
    return ReportMessageModel(
      messageId: json['messageId'] ?? '',
      reportId: json['reportId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderRole: json['senderRole'] ?? '',
      messageText: json['messageText'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
