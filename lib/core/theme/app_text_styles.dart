// lib/core/theme/app_text_styles.dart
//
// Typography for a trilingual (English / Sinhala / Tamil) app.
//
// Why this is language-aware rather than one fixed TextTheme:
//
// The app previously specified no font at all, so Latin rendered in Roboto
// while Sinhala and Tamil fell back to whatever the device happened to ship.
// That is unpredictable across the budget Android devices this app targets,
// and the fallback rarely matches Roboto's weight or x-height, so mixed
// screens looked visually inconsistent.
//
// We now bundle three matched faces from the Noto family — designed as one
// system precisely to solve cross-script consistency — and select the primary
// face from the active app language, with the other two plus the Latin face
// listed as fallbacks. The fallback list matters: a Sinhala UI still shows
// Latin crop names, disease names, numbers and units, and a Tamil UI likewise,
// so every face needs the others behind it. Without the fallback chain those
// runs would render as tofu boxes.
//
// Sizing rules:
//  * Body text floors at 14sp. The old code had 11sp and 12sp labels, which is
//    too small for outdoor use and for an audience skewing older / lower
//    literacy. Nothing here goes below 12, and only for non-essential labels.
//  * Line heights are generous (1.3–1.5). Material's defaults are tuned for
//    Latin; Sinhala and Tamil have taller ascenders/descenders and stacked
//    diacritics that collide at Latin line heights.
//  * These sizes are pre-scaling. The app applies the user's accessibility
//    text-scale via MediaQuery on top, so never multiply by a scale factor
//    here or at a call site.

import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const String latin = 'NotoSans';
  static const String sinhala = 'NotoSansSinhala';
  static const String tamil = 'NotoSansTamil';

  /// Primary face for [languageCode], defaulting to Latin.
  static String fontFamilyFor(String languageCode) {
    switch (languageCode) {
      case 'si':
        return sinhala;
      case 'ta':
        return tamil;
      default:
        return latin;
    }
  }

  /// The other faces, so mixed-script runs never fall through to tofu.
  static List<String> fontFamilyFallbackFor(String languageCode) {
    final primary = fontFamilyFor(languageCode);
    return [latin, sinhala, tamil]..removeWhere((f) => f == primary);
  }

  /// Full text theme for [languageCode]. Colours come from [AppColors] so
  /// text is legible on light surfaces in bright light by default.
  static TextTheme textThemeFor(String languageCode) {
    final family = fontFamilyFor(languageCode);
    final fallback = fontFamilyFallbackFor(languageCode);

    TextStyle style({
      required double size,
      required FontWeight weight,
      required double height,
      Color color = AppColors.onSurface,
      double? letterSpacing,
    }) {
      return TextStyle(
        fontFamily: family,
        fontFamilyFallback: fallback,
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color,
        letterSpacing: letterSpacing,
      );
    }

    return TextTheme(
      // Display — splash and onboarding hero text only.
      displayLarge: style(size: 40, weight: FontWeight.w700, height: 1.2),
      displayMedium: style(size: 34, weight: FontWeight.w700, height: 1.2),
      displaySmall: style(size: 29, weight: FontWeight.w600, height: 1.25),

      // Headline — screen titles, result headings.
      headlineLarge: style(size: 26, weight: FontWeight.w700, height: 1.3),
      headlineMedium: style(size: 23, weight: FontWeight.w600, height: 1.3),
      headlineSmall: style(size: 20, weight: FontWeight.w600, height: 1.35),

      // Title — card headers, list-row primary text, AppBar.
      titleLarge: style(size: 19, weight: FontWeight.w600, height: 1.35),
      titleMedium: style(size: 17, weight: FontWeight.w600, height: 1.4),
      titleSmall: style(size: 15, weight: FontWeight.w600, height: 1.4),

      // Body — everything a farmer actually has to read. Floors at 14.
      bodyLarge: style(size: 17, weight: FontWeight.w400, height: 1.5),
      bodyMedium: style(size: 15, weight: FontWeight.w400, height: 1.5),
      bodySmall: style(
        size: 14,
        weight: FontWeight.w400,
        height: 1.45,
        color: AppColors.onSurfaceVariant,
      ),

      // Label — buttons, chips, badges. Buttons stay at 16 so the primary
      // action is never smaller than body text.
      labelLarge: style(size: 16, weight: FontWeight.w600, height: 1.3),
      labelMedium: style(size: 14, weight: FontWeight.w600, height: 1.3),
      labelSmall: style(
        size: 12,
        weight: FontWeight.w600,
        height: 1.3,
        color: AppColors.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }
}
