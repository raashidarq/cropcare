class LocalUser {
  final String id;
  final String? remoteUserId;
  final String? email;
  final String? phoneNumber;
  final bool isGuest;
  final String? sessionToken;
  final String? sessionRefreshToken;
  final DateTime? sessionExpiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LocalUser({
    required this.id,
    this.remoteUserId,
    this.email,
    this.phoneNumber,
    this.isGuest = true,
    this.sessionToken,
    this.sessionRefreshToken,
    this.sessionExpiresAt,
    required this.createdAt,
    required this.updatedAt,
  });
}
