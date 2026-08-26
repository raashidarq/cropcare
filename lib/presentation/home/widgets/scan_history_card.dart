// lib/presentation/home/widgets/scan_history_card.dart
//
// One row in the scan history.
//
// The old row was a thumbnail plus a coloured "status pill" whose colour was
// derived by logic that disagreed with the diagnosis screen's own colours for
// the same scan. This version leads with the thing a farmer recognises — the
// photo and the crop — states the outcome in words, and uses the shared
// severity mapping so a scan looks the same everywhere in the app.

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/crop_visuals.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/diagnosis.dart';
import '../../../domain/entities/scan.dart';
import '../../../domain/entities/scan_history_item.dart';
import '../../onboarding/localization/localization_provider.dart';
import '../../shared/widgets/app_components.dart';

class ScanHistoryCard extends StatelessWidget {
  final ScanHistoryItem item;
  final VoidCallback onTap;

  const ScanHistoryCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageCode = LocalizationProvider.of(context)?.languageCode ?? 'en';
    final diagnosis = item.diagnosis;
    final visual = CropVisuals.forCrop(item.crop?.id ?? item.scan.cropId);

    final cropName = item.crop?.getLocalizedName(languageCode) ??
        _titleCase(item.scan.cropId) ??
        context.tr('unknown_disease');
    final outcome = _outcome(context, diagnosis, item.scan);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.smPlus),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumbnail(path: item.scan.imageLocalPath, visual: visual),
          const SizedBox(width: AppSpacing.smPlus),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(visual.icon, size: 16, color: visual.color),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        cropName,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  outcome.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: outcome.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _relativeDate(context, item.scan.capturedAt),
                        style: theme.textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Shown only when a scan has NOT reached the cloud.
                    // Marking the synced ones would put a badge on almost
                    // every row and say nothing; the exception is the
                    // information. Settings has only ever had an aggregate
                    // pending count, so there was no way to tell WHICH scan
                    // was still waiting.
                    if (item.scan.remoteScanId == null) ...[
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 14,
                        color: AppColors.onSurfaceVariant,
                        semanticLabel: context.tr('not_backed_up'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    if (diagnosis != null && !diagnosis.isHealthy)
                      Text(
                        '${(diagnosis.confidence * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.confidenceColor(
                            diagnosis.confidence,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  _Outcome _outcome(
    BuildContext context,
    Diagnosis? diagnosis,
    Scan scan,
  ) {
    if (scan.status == ScanStatus.invalidImage) {
      return _Outcome(
        context.tr('image_rejected_title'),
        AppColors.onSurfaceVariant,
      );
    }
    if (diagnosis == null) {
      return _Outcome(context.tr('analyzing'), AppColors.onSurfaceVariant);
    }
    switch (diagnosis.resultState) {
      case DiagnosisResultState.analysisFailed:
        return _Outcome(context.tr('badge_failed'), AppColors.error);
      case DiagnosisResultState.unsupported:
        return _Outcome(
          context.tr('badge_unsupported'),
          AppColors.onSurfaceVariant,
        );
      case DiagnosisResultState.lowConfidence:
      case DiagnosisResultState.confident:
        if (diagnosis.isHealthy) {
          return _Outcome(
            context.tr('result_healthy_title'),
            AppColors.success,
          );
        }
        return _Outcome(
          _titleCase(diagnosis.diseaseId) ?? context.tr('unknown_disease'),
          AppColors.severityColor(diagnosis.severity),
        );
    }
  }

  /// Turns `tomato_late_blight` into `Tomato Late Blight`.
  ///
  /// NOTE: this is English-only. The `disease` table does carry `name_si` and
  /// `name_ta`, but a Diagnosis only holds a disease *id*, so the localized
  /// name is not reachable here without threading the disease row through the
  /// scan-history query. Worth doing — tracked as follow-up — since disease
  /// names are exactly the text a Sinhala- or Tamil-speaking farmer most
  /// needs in their own language.
  static String? _titleCase(String? id) {
    if (id == null || id.isEmpty) return null;
    return id
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _relativeDate(BuildContext context, DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return context.tr('just_now');
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${when.year}-${when.month.toString().padLeft(2, '0')}-'
        '${when.day.toString().padLeft(2, '0')}';
  }
}

class _Outcome {
  final String label;
  final Color color;

  const _Outcome(this.label, this.color);
}

class _Thumbnail extends StatelessWidget {
  final String path;
  final CropVisual visual;

  const _Thumbnail({required this.path, required this.visual});

  @override
  Widget build(BuildContext context) {
    const size = 64.0;
    final file = File(path);
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return ClipRRect(
      borderRadius: AppRadius.md,
      child: SizedBox(
        width: size,
        height: size,
        child: file.existsSync()
            ? Image.file(
                file,
                fit: BoxFit.cover,
                // Decode at thumbnail size. A full-resolution camera photo
                // decoded per row will stutter or OOM a budget device once
                // the history grows.
                cacheWidth: (size * dpr).round(),
                cacheHeight: (size * dpr).round(),
                errorBuilder: (_, _, _) => _Placeholder(visual: visual),
              )
            : _Placeholder(visual: visual),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final CropVisual visual;

  const _Placeholder({required this.visual});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Icon(visual.icon, color: visual.color, size: 28),
      ),
    );
  }
}
