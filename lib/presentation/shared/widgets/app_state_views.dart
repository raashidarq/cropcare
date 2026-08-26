// lib/presentation/shared/widgets/app_state_views.dart
//
// Shared loading / empty / error views.
//
// These exist to fix a specific problem: several screens rendered raw
// exception text straight to the user — `Text('Error: ${snapshot.error}')` in
// crop_selection_screen, capture_screen and scan_result_screen. A Dart
// exception string is meaningless and alarming to a farmer, and it is always
// in English regardless of the app language.
//
// The rule these encode: a user-facing error shows a localized, plain-language
// message and a way forward. Technical detail is available for debugging, but
// never the default presentation.

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// Centred branded spinner with an optional label.
class AppLoadingView extends StatelessWidget {
  final String? message;

  const AppLoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Neutral "nothing here yet" state with an optional call to action.
class AppEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return _StateScaffold(
      icon: icon,
      iconColor: AppColors.onSurfaceVariant,
      iconBackground: AppColors.surfaceVariant,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

/// User-facing error state.
///
/// [message] must already be localized and human-readable. [technicalDetail]
/// is optional and collapsed behind a disclosure — pass the raw exception
/// there if it is useful for support, never as [message].
class AppErrorView extends StatelessWidget {
  final String title;
  final String message;
  final String? technicalDetail;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  const AppErrorView({
    super.key,
    required this.title,
    required this.message,
    this.technicalDetail,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return _StateScaffold(
      icon: icon,
      iconColor: AppColors.error,
      iconBackground: AppColors.errorContainer,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      footer: technicalDetail == null
          ? null
          : _TechnicalDetail(detail: technicalDetail!),
    );
  }
}

class _StateScaffold extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? footer;

  const _StateScaffold({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              // Decorative: the title and message carry the meaning, so don't
              // announce the icon separately to screen readers.
              child: ExcludeSemantics(
                child: Icon(icon, size: 44, color: iconColor),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
            if (footer != null) ...[
              const SizedBox(height: AppSpacing.md),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class _TechnicalDetail extends StatefulWidget {
  final String detail;

  const _TechnicalDetail({required this.detail});

  @override
  State<_TechnicalDetail> createState() => _TechnicalDetailState();
}

class _TechnicalDetailState extends State<_TechnicalDetail> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _expanded = !_expanded),
          icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          label: Text(_expanded ? 'Hide details' : 'Show details'),
        ),
        if (_expanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.smPlus),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.sm,
            ),
            child: SelectableText(
              widget.detail,
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
