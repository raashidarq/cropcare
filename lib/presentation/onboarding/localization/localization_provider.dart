import 'package:flutter/material.dart';

import 'app_localizations.dart';

class LocalizationProvider extends InheritedWidget {
  final String languageCode;

  const LocalizationProvider({
    super.key,
    required this.languageCode,
    required super.child,
  });

  static LocalizationProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocalizationProvider>();
  }

  String tr(String key) {
    return AppLocalizations.get(key, languageCode);
  }

  @override
  bool updateShouldNotify(LocalizationProvider oldWidget) {
    return oldWidget.languageCode != languageCode;
  }
}

extension LocalizationExtension on BuildContext {
  String tr(String key) {
    final provider = LocalizationProvider.of(this);
    return provider?.tr(key) ?? AppLocalizations.get(key, 'en');
  }
}
