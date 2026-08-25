enum ScanStatus {
  created('CREATED'),
  validating('VALIDATING'),
  analyzing('ANALYZING'),
  diagnosed('DIAGNOSED'),
  completed('COMPLETED'),
  escalated('ESCALATED'),
  shared('SHARED'),
  resolved('RESOLVED'),
  userCancelled('USER_CANCELLED'),
  invalidImage('INVALID_IMAGE'),
  analysisFailed('ANALYSIS_FAILED');

  final String value;
  const ScanStatus(this.value);

  static ScanStatus fromString(String raw) {
    return ScanStatus.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => ScanStatus.created,
    );
  }
}

class Scan {
  final String id;
  final String? remoteScanId;
  final String userId;
  final String cropId;
  final String imageLocalPath;
  final String? imageRemoteUrl;
  final ScanStatus status;
  final DateTime capturedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Scan({
    required this.id,
    this.remoteScanId,
    required this.userId,
    required this.cropId,
    required this.imageLocalPath,
    this.imageRemoteUrl,
    required this.status,
    required this.capturedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Scan copyWith({
    String? id,
    String? remoteScanId,
    String? userId,
    String? cropId,
    String? imageLocalPath,
    String? imageRemoteUrl,
    ScanStatus? status,
    DateTime? capturedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Scan(
      id: id ?? this.id,
      remoteScanId: remoteScanId ?? this.remoteScanId,
      userId: userId ?? this.userId,
      cropId: cropId ?? this.cropId,
      imageLocalPath: imageLocalPath ?? this.imageLocalPath,
      imageRemoteUrl: imageRemoteUrl ?? this.imageRemoteUrl,
      status: status ?? this.status,
      capturedAt: capturedAt ?? this.capturedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
