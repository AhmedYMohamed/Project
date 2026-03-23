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
  final DateTime createdAt;
  final List<AttachmentModel> attachments;

  ReportModel({
    required this.reportId,
    required this.title,
    required this.descriptionText,
    required this.status,
    required this.categoryId,
    required this.createdAt,
    required this.attachments,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      reportId: json['reportId'] ?? '',
      title: json['title'] ?? '',
      descriptionText: json['descriptionText'] ?? '',
      status: json['status'] ?? 'Submitted',
      categoryId: json['categoryId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      attachments: (json['attachments'] as List? ?? [])
          .map((a) => AttachmentModel.fromJson(a))
          .toList(),
    );
  }
}

class AttachmentModel {
  final String attachmentId;
  final String blobStorageUri;
  final String fileType;

  AttachmentModel({
    required this.attachmentId,
    required this.blobStorageUri,
    required this.fileType,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      attachmentId: json['attachmentId'] ?? '',
      blobStorageUri: json['blobStorageUri'] ?? '',
      fileType: json['fileType'] ?? 'document',
    );
  }
}
