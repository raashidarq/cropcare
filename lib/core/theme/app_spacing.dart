// lib/core/theme/app_spacing.dart
//
// An 8pt spacing scale. Use these instead of raw numbers in EdgeInsets,
// SizedBox and Gap-style spacers.
//
// Before this existed the codebase used EdgeInsets.all(4/12/14/16/20/24/28/32)
// essentially at random — sometimes three different values inside one card —
// which is a large part of why the UI read as untidy. When migrating an old
// literal, round to the NEAREST token rather than adding a new one; the value
// of a scale is that it is small.

class AppSpacing {
  const AppSpacing._();

  /// 4 — hairline gaps, icon/label separation.
  static const double xs = 4;

  /// 8 — tight internal padding, chip padding.
  static const double sm = 8;

  /// 12 — dense rows; the one half-step, kept because 8 is too tight and 16
  /// too loose for list rows and chips at larger text scales.
  static const double smPlus = 12;

  /// 16 — the default. Screen padding, card padding, gap between fields.
  static const double md = 16;

  /// 24 — separation between distinct groups within a screen.
  static const double lg = 24;

  /// 32 — major section breaks, generous top/bottom screen padding.
  static const double xl = 32;

  /// 48 — hero spacing on sparse screens (splash, onboarding, empty states).
  static const double xxl = 48;

  /// Minimum interactive target, per Material and WCAG 2.5.5.
  /// Any custom GestureDetector/InkWell must reserve at least this.
  static const double minTouchTarget = 48;
}
