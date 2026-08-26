// lib/presentation/shared/widgets/app_components.dart
//
// Shared building blocks for CropCare's UI.
//
// The app previously composed every screen out of raw Card/Container/Row with
// per-screen padding, radii and colours, so the same concept (a status, a
// severity, a confidence score) looked different on each screen. These are the
// canonical versions — build screens out of these rather than re-deriving them.
//
// Audience notes that shaped these:
//  * Low digital literacy: nothing is icon-only. Every status carries an icon
//    AND a word, and every tappable card looks tappable (elevation + chevron).
//  * Outdoor use: solid fills, no translucent text backgrounds, large targets.
//  * Trilingual: every label wraps or ellipsises; nothing assumes English
//    string lengths.

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

// =============================================================================
// Surfaces
// =============================================================================

/// Standard bordered surface. Flat by default — CropCare uses borders and
/// spacing for separation rather than stacked shadows, which stay legible in
/// bright sunlight where soft shadows disappear.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);

    return Material(
      color: color ?? AppColors.surface,
      borderRadius: AppRadius.lg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lg,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lg,
            border: Border.all(
              color: borderColor ?? AppColors.outlineVariant,
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// A tappable row: icon tile, title, supporting line, chevron.
/// Used for the primary choices on a screen (take photo, choose from gallery,
/// settings entries) so they are unmistakably interactive.
class AppActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? iconBackground;
  final bool emphasized;
  final Widget? trailing;

  const AppActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.iconBackground,
    this.emphasized = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      color: emphasized ? AppColors.primaryContainer : AppColors.surface,
      borderColor: emphasized ? AppColors.primaryContainer : null,
      child: Row(
        children: [
          _IconTile(
            icon: icon,
            color: iconColor ??
                (emphasized ? AppColors.onPrimary : AppColors.primary),
            background: iconBackground ??
                (emphasized ? AppColors.primary : AppColors.surfaceVariant),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                color: emphasized
                    ? AppColors.onPrimaryContainer
                    : AppColors.onSurfaceVariant,
              ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;

  const _IconTile({
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: background, borderRadius: AppRadius.md),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

// =============================================================================
// Section header
// =============================================================================

/// Title for a group of content, with an optional trailing action.
/// Uses sentence-case title styling rather than the uppercase micro-labels the
/// app used before — uppercase is harder to read and does not apply to Sinhala
/// or Tamil at all, so it made the three languages look inconsistent.
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

// =============================================================================
// Status / severity / confidence
// =============================================================================

/// Pill combining an icon and a word. Never colour alone — colour-blind users
/// and anyone glancing at a glary screen still get the meaning, and the
/// Semantics label carries it to screen readers.
class AppStatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;
  final String? semanticsLabel;

  const AppStatusChip({
    super.key,
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    this.semanticsLabel,
  });

  /// Chip describing a diagnosis severity, using the single shared mapping.
  factory AppStatusChip.severity(String? severity, String label) {
    final color = AppColors.severityColor(severity);
    return AppStatusChip(
      icon: switch (severity?.toLowerCase()) {
        'high' => Icons.priority_high_rounded,
        'moderate' => Icons.warning_amber_rounded,
        'low' => Icons.info_outline_rounded,
        _ => Icons.help_outline_rounded,
      },
      label: label,
      foreground: color,
      background: AppColors.severityContainer(severity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: semanticsLabel ?? label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.smPlus,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.full,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(color: foreground),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal confidence bar with a numeric readout.
///
/// Deliberately not green at the top end: a high-confidence guess from a
/// 38-class model is still a guess, and this app's known failure mode is
/// looking more certain than it is. The bar communicates magnitude; the
/// caption keeps it honest.
class AppConfidenceMeter extends StatelessWidget {
  final double confidence;
  final String label;
  final String? caption;

  const AppConfidenceMeter({
    super.key,
    required this.confidence,
    required this.label,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (confidence * 100).clamp(0, 100).toStringAsFixed(0);
    final color = AppColors.confidenceColor(confidence);

    return Semantics(
      label: '$label $pct%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: theme.textTheme.labelMedium),
              ),
              Text(
                '$pct%',
                style: theme.textTheme.titleSmall?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.full,
            child: LinearProgressIndicator(
              value: confidence.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(caption!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Banners
// =============================================================================

/// Inline message with an icon, used for advisories (AI disclaimer, low
/// confidence, offline, session expired).
class AppBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? title;
  final Color foreground;
  final Color background;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppBanner({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    required this.foreground,
    required this.background,
    this.actionLabel,
    this.onAction,
  });

  factory AppBanner.warning({
    required String message,
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      AppBanner(
        icon: Icons.warning_amber_rounded,
        message: message,
        title: title,
        foreground: AppColors.onWarningContainer,
        background: AppColors.warningContainer,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  factory AppBanner.info({
    required String message,
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      AppBanner(
        icon: Icons.info_outline_rounded,
        message: message,
        title: title,
        foreground: AppColors.onInfoContainer,
        background: AppColors.infoContainer,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  /// "This is an AI suggestion, not an agronomist" — deliberately amber and
  /// always present on results, because the model can be confidently wrong.
  factory AppBanner.aiDisclaimer({
    required String message,
    String? title,
  }) =>
      AppBanner(
        icon: Icons.smart_toy_outlined,
        message: message,
        title: title,
        foreground: AppColors.onAiDisclaimerContainer,
        background: AppColors.aiDisclaimerContainer,
      );

  factory AppBanner.error({
    required String message,
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      AppBanner(
        icon: Icons.error_outline_rounded,
        message: message,
        title: title,
        foreground: AppColors.onErrorContainer,
        background: AppColors.errorContainer,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.smPlus),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: AppSpacing.smPlus),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(color: foreground),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  // Left-aligned, tight padding so it reads as part of the
                  // banner rather than a floating control.
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: foreground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Stats
// =============================================================================

/// Compact number + label tile for the home dashboard.
class AppStatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const AppStatTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      button: onTap != null,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.smPlus,
          vertical: AppSpacing.smPlus,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(color: color),
              maxLines: 1,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Segmented toggle
// =============================================================================

/// Two-or-more-way exclusive choice rendered as a pill of segments.
///
/// Replaces hand-rolled GestureDetector pairs, which duplicated the same
/// twenty lines per segment and — more importantly — sized themselves purely
/// by text padding, so segments could fall under the 48dp minimum target at
/// small text scales. Each segment here reserves [AppSpacing.minTouchTarget].
class AppSegmentedToggle<T> extends StatelessWidget {
  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  const AppSegmentedToggle({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.md,
      ),
      child: Row(
        children: [
          for (final segment in segments)
            Expanded(
              child: Semantics(
                button: true,
                selected: segment.value == selected,
                label: segment.label,
                child: Material(
                  color: segment.value == selected
                      ? AppColors.surface
                      : Colors.transparent,
                  borderRadius: AppRadius.sm,
                  child: InkWell(
                    key: segment.key,
                    onTap: () => onChanged(segment.value),
                    borderRadius: AppRadius.sm,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: AppSpacing.minTouchTarget,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (segment.icon != null) ...[
                            Icon(
                              segment.icon,
                              size: 18,
                              color: segment.value == selected
                                  ? AppColors.primary
                                  : AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Flexible(
                            child: Text(
                              segment.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: segment.value == selected
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AppSegment<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Key? key;

  const AppSegment({
    required this.value,
    required this.label,
    this.icon,
    this.key,
  });
}
