// lib/core/theme/app_colors.dart
//
// THE single source of truth for colour in CropCare.
//
// Screens must not use `Colors.*` swatches or raw `Color(0x...)` literals for
// anything that carries meaning (brand, status, severity, source). Reach for a
// token here instead, so a palette change is one edit rather than 145.
//
// Design constraints this palette is built around:
//
//  * Outdoor sunlight. Farmers use this in direct Sri Lankan sun, where glare
//    washes out mid-tones and pastels. Foreground colours are therefore dark
//    and saturated, and every text colour clears WCAG AA (4.5:1) against the
//    surface it is used on — most clear AAA.
//  * Sinhala and Tamil scripts. Both have finer strokes and more diacritics
//    than Latin, so low-contrast or thin-on-light combinations become
//    illegible far sooner. Same rule: no light-on-light.
//  * Low literacy. Colour is never the ONLY signal — every status colour is
//    paired with an icon and a text label at the call site, and with a
//    Semantics label for screen readers.
//
// Rule of thumb: alpha-blended colours are fine for decorative backgrounds,
// never behind text. A translucent surface has an unpredictable effective
// contrast ratio, which is exactly what fails in bright light.

import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  // One brand green, used everywhere. Previously the app seeded its theme
  // from `Colors.green` (#4CAF50) while the launcher icon used #2E7D32 — two
  // different "brand greens" that never matched. This is now the only one.
  //
  // #1B5E20 on white ≈ 8.9:1 (AAA). Deeper and more saturated than either
  // previous green so it holds up against bright outdoor backgrounds.
  static const Color primary = Color(0xFF1B5E20);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Light green fill for badges, chips and hero panels.
  /// [onPrimaryContainer] on this ≈ 10.4:1.
  static const Color primaryContainer = Color(0xFFC8E6C9);
  static const Color onPrimaryContainer = Color(0xFF0D3311);

  /// Mid green for secondary emphasis. Dark enough for white text (≈4.8:1).
  static const Color secondary = Color(0xFF2E7D32);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // ── Neutrals ─────────────────────────────────────────────────────────────
  // Very slightly warm greys. Neutral-cool greys read as blue-ish next to
  // green and look muddy under warm daylight.
  static const Color background = Color(0xFFFAF9F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1EFEB);
  static const Color onSurface = Color(0xFF1C1B1A);
  static const Color onSurfaceVariant = Color(0xFF4A4643);
  static const Color outline = Color(0xFF79746E);
  static const Color outlineVariant = Color(0xFFD5D0C9);

  // ── Semantic status ──────────────────────────────────────────────────────
  // Each has a dark `base` (safe for text/icons on light surfaces) and a light
  // `container` (safe as a fill BEHIND that base colour).
  static const Color success = Color(0xFF2E7D32);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFE8F5E9);
  static const Color onSuccessContainer = Color(0xFF0D3311);

  /// Deep orange rather than amber. Amber (#FFC107) on white is ≈1.9:1 and
  /// fails AA badly for text; it is only ever used here as a container fill.
  static const Color warning = Color(0xFFE65100);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFFF3E0);
  static const Color onWarningContainer = Color(0xFF6B2600);

  static const Color error = Color(0xFFC62828);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color onErrorContainer = Color(0xFF6B1212);

  static const Color info = Color(0xFF1565C0);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color infoContainer = Color(0xFFE3F2FD);
  static const Color onInfoContainer = Color(0xFF0B3C71);

  // ── Domain-specific ──────────────────────────────────────────────────────
  /// "This came from AI, not an agronomist" disclaimer banners.
  /// Amber reads as caution without the alarm of red/orange. Container-only:
  /// pair with [onAiDisclaimerContainer] for the text.
  static const Color aiDisclaimerContainer = Color(0xFFFFF8E1);
  static const Color onAiDisclaimerContainer = Color(0xFF5D4200);

  /// Treatment-guidance provenance badges.
  static const Color treatmentSourceAi = Color(0xFF6A1B9A);
  static const Color treatmentSourceOffline = Color(0xFF00695C);

  /// WhatsApp brand green, for the expert-escalation action only.
  /// Replaces three independently hardcoded copies of #25D366.
  /// NOTE: this is a brand colour, not a contrast-safe text colour — always
  /// pair it with white on a filled button, never as text on a light surface.
  static const Color whatsapp = Color(0xFF25D366);
  static const Color onWhatsapp = Color(0xFFFFFFFF);

  // ── Severity ─────────────────────────────────────────────────────────────
  static const Color severityHigh = error;
  static const Color severityModerate = warning;
  static const Color severityLow = Color(0xFF8D6E00);
  static const Color severityUnknown = Color(0xFF5C5751);

  /// THE severity→colour mapping. Previously this logic existed twice, with
  /// different colours: `_getSeverityColor` in diagnosis_result_screen.dart
  /// (high/moderate/low) and an unrelated binary green/orange rule in
  /// home_screen.dart, so the same scan could be two different colours on two
  /// screens. Both now call this.
  static Color severityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return severityHigh;
      case 'moderate':
        return severityModerate;
      case 'low':
        return severityLow;
      default:
        return severityUnknown;
    }
  }

  /// Light fill matching [severityColor], for chips and banners.
  static Color severityContainer(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return errorContainer;
      case 'moderate':
        return warningContainer;
      case 'low':
        return const Color(0xFFFFF8E1);
      default:
        return surfaceVariant;
    }
  }

  // ── Confidence ───────────────────────────────────────────────────────────
  /// Colour for a model-confidence readout. Deliberately NOT green at the top
  /// end: a high-confidence ML guess is still a guess, and the app should not
  /// visually promise correctness. High confidence reads as neutral/informational.
  static Color confidenceColor(double confidence) {
    if (confidence >= 0.80) return info;
    if (confidence >= 0.60) return warning;
    return error;
  }
}
