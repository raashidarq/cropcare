class SettingsState {
  final String? expandedSection;

  const SettingsState({this.expandedSection});

  SettingsState copyWith({String? expandedSection}) {
    return SettingsState(
      expandedSection: expandedSection ?? this.expandedSection,
    );
  }
}
