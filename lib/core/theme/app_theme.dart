// lib/core/theme/app_theme.dart
//
// Builds the ThemeData the whole app runs on. This is the single integration
// point for the design system: app.dart calls AppTheme.light() /
// AppTheme.highContrast() and every screen then reads Theme.of(context).
//
// Component themes (buttons, cards, chips, inputs) are configured HERE rather
// than overridden per-widget, so screens don't need to restate radius,
// padding or colour to look right — and so a farmer gets 48dp touch targets
// everywhere without each screen having to remember.

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light(String languageCode) =>
      _build(languageCode: languageCode, highContrast: false);

  /// Higher-contrast variant driven by the accessibility setting. Darkens
  /// foregrounds and strengthens borders rather than switching palette, so
  /// the app stays recognisable when the setting is toggled.
  static ThemeData highContrast(String languageCode) =>
      _build(languageCode: languageCode, highContrast: true);

  static ThemeData _build({
    required String languageCode,
    required bool highContrast,
  }) {
    final textTheme = AppTextStyles.textThemeFor(languageCode);

    final onSurface =
        highContrast ? const Color(0xFF000000) : AppColors.onSurface;
    final onSurfaceVariant = highContrast
        ? const Color(0xFF2B2724)
        : AppColors.onSurfaceVariant;
    final outline =
        highContrast ? const Color(0xFF3D3A36) : AppColors.outline;

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.successContainer,
      onSecondaryContainer: AppColors.onSuccessContainer,
      tertiary: AppColors.info,
      onTertiary: AppColors.onInfo,
      tertiaryContainer: AppColors.infoContainer,
      onTertiaryContainer: AppColors.onInfoContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: onSurface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: AppColors.outlineVariant,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: const Color(0xFF31302D),
      onInverseSurface: const Color(0xFFF4F1EC),
      inversePrimary: AppColors.primaryContainer,
    );

    final baseTextTheme = textTheme.apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: baseTextTheme,
      // Ensures Material's own widgets (dialogs, menus) pick up the right
      // face for the active language too.
      fontFamily: AppTextStyles.fontFamilyFor(languageCode),
      fontFamilyFallback: AppTextStyles.fontFamilyFallbackFor(languageCode),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: AppColors.onPrimary,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md,
          side: BorderSide(color: AppColors.outlineVariant),
        ),
      ),

      // Every primary action is at least 48dp tall and uses label-large (16sp),
      // so the main call to action is never small or cramped.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(0, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.smPlus,
          ),
          elevation: 0,
          textStyle: baseTextTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.smPlus,
          ),
          side: BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: baseTextTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: baseTextTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(0, AppSpacing.minTouchTarget),
          textStyle: baseTextTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primaryContainer,
        labelStyle: baseTextTheme.labelMedium,
        side: BorderSide(color: AppColors.outlineVariant),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.smPlus,
          vertical: AppSpacing.sm,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.full),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.smPlus,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: baseTextTheme.bodyMedium,
        hintStyle: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF31302D),
        contentTextStyle: baseTextTheme.bodyMedium?.copyWith(
          color: const Color(0xFFF4F1EC),
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
        titleTextStyle: baseTextTheme.titleLarge,
        contentTextStyle: baseTextTheme.bodyMedium,
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.outlineVariant,
        space: 1,
        thickness: 1,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        titleTextStyle: baseTextTheme.titleSmall,
        subtitleTextStyle: baseTextTheme.bodySmall,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }
}
