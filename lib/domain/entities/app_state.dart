class AppState {
  final bool onboardingCompleted;
  final String languageCode;
  final DateTime? firstLaunchAt;

  const AppState({
    required this.onboardingCompleted,
    required this.languageCode,
    this.firstLaunchAt,
  });

  factory AppState.initial() {
    return const AppState(
      onboardingCompleted: false,
      languageCode: 'en',
      firstLaunchAt: null,
    );
  }

  AppState copyWith({
    bool? onboardingCompleted,
    String? languageCode,
    DateTime? firstLaunchAt,
  }) {
    return AppState(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      languageCode: languageCode ?? this.languageCode,
      firstLaunchAt: firstLaunchAt ?? this.firstLaunchAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppState &&
          runtimeType == other.runtimeType &&
          onboardingCompleted == other.onboardingCompleted &&
          languageCode == other.languageCode &&
          firstLaunchAt == other.firstLaunchAt;

  @override
  int get hashCode =>
      onboardingCompleted.hashCode ^
      languageCode.hashCode ^
      firstLaunchAt.hashCode;
}
