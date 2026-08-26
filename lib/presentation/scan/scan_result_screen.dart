// lib/presentation/scan/scan_result_screen.dart
//
// The "this scan has no diagnosis" screen.
//
// Reached from two places: the capture flow when a scan row is created but
// inference has not produced a result, and History when an older scan has no
// diagnosis attached.
//
// What this screen used to be: a field dump. It printed the scan UUID, the raw
// crop id, the enum status string, an ISO-8601 timestamp and the full
// filesystem path of the image — to a farmer. It also rendered
// `Error: $_errorMessage` straight from the exception, which violates the
// no-raw-exceptions rule (CODEBASE_MAP §9 rule 19).
//
// What it is now: the photo, the crop, one sentence saying what state the scan
// is in and what the farmer can do about it. Every state that can land here
// gets an explanation and, where one exists, an action. Nothing is shown that
// a farmer cannot act on.

import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/crop_visuals.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/scan.dart';
import '../../domain/usecases/scan/get_scan_by_id_use_case.dart';
import '../onboarding/localization/localization_provider.dart';
import '../shared/widgets/app_components.dart';
import '../shared/widgets/app_state_views.dart';

class ScanResultScreen extends StatefulWidget {
  final Scan? scan;
  final String? scanId;
  final GetScanByIdUseCase? getScanByIdUseCase;

  const ScanResultScreen({
    super.key,
    this.scan,
    this.scanId,
    this.getScanByIdUseCase,
  }) : assert(scan != null || (scanId != null && getScanByIdUseCase != null));

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  Scan? _scan;
  bool _isLoading = false;

  /// Kept only to populate `AppErrorView.technicalDetail`, which is collapsed
  /// by default. It is never the primary message.
  String? _technicalDetail;

  @override
  void initState() {
    super.initState();
    if (widget.scan != null) {
      _scan = widget.scan;
    } else {
      _fetchScan();
    }
  }

  Future<void> _fetchScan() async {
    setState(() {
      _isLoading = true;
      _technicalDetail = null;
    });
    try {
      final fetched = await widget.getScanByIdUseCase!(widget.scanId!);
      if (!mounted) return;
      setState(() {
        _scan = fetched;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _technicalDetail = e.toString();
        _isLoading = false;
      });
    }
  }

  void _scanAgain() => Navigator.of(context).popUntil((route) => route.isFirst);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('scan_result_title')),
        elevation: 0,
      ),
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    if (_isLoading) {
      return const AppLoadingView();
    }

    if (_technicalDetail != null) {
      return AppErrorView(
        title: context.tr('scan_load_failed_title'),
        message: context.tr('scan_load_failed_msg'),
        technicalDetail: _technicalDetail,
        actionLabel: context.tr('retry_btn'),
        onAction: _fetchScan,
      );
    }

    final scan = _scan;
    if (scan == null) {
      return AppEmptyView(
        icon: Icons.image_not_supported_outlined,
        title: context.tr('scan_not_found_title'),
        message: context.tr('scan_not_found_msg'),
        actionLabel: context.tr('scan_again'),
        onAction: _scanAgain,
      );
    }

    final outcome = _outcomeFor(context, scan.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The photo is what the farmer recognises the scan by. It leads,
          // exactly as it does on the diagnosis screen, and shares that
          // screen's Hero tag so navigating between them is continuous.
          Hero(
            tag: 'scan-image-${scan.id}',
            child: ClipRRect(
              borderRadius: AppRadius.lg,
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: _ScanImage(path: scan.imageLocalPath),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _CropRow(cropId: scan.cropId, capturedAt: scan.capturedAt),
          const SizedBox(height: AppSpacing.md),
          outcome.banner,
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: AppSpacing.minTouchTarget,
            child: ElevatedButton.icon(
              key: const Key('scan_result_scan_again_button'),
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(context.tr('scan_again')),
              onPressed: _scanAgain,
            ),
          ),
        ],
      ),
    );
  }

  /// Maps the scan status to something a farmer can read and act on.
  ///
  /// Only statuses that can reach this screen are handled explicitly — a scan
  /// with a diagnosis is routed to `DiagnosisResultScreen` instead.
  _Outcome _outcomeFor(BuildContext context, ScanStatus status) {
    switch (status) {
      case ScanStatus.invalidImage:
        return _Outcome(
          AppBanner.warning(
            title: context.tr('image_rejected_title'),
            message: context.tr('scan_invalid_image_msg'),
          ),
        );
      case ScanStatus.analysisFailed:
        return _Outcome(
          AppBanner.error(
            title: context.tr('badge_failed'),
            message: context.tr('scan_analysis_failed_msg'),
          ),
        );
      case ScanStatus.userCancelled:
        return _Outcome(
          AppBanner.info(
            title: context.tr('scan_cancelled_title'),
            message: context.tr('scan_cancelled_msg'),
          ),
        );
      case ScanStatus.created:
      case ScanStatus.validating:
      case ScanStatus.analyzing:
        return _Outcome(
          AppBanner.info(
            title: context.tr('analyzing'),
            message: context.tr('scan_pending_msg'),
          ),
        );
      case ScanStatus.diagnosed:
      case ScanStatus.completed:
      case ScanStatus.escalated:
      case ScanStatus.shared:
      case ScanStatus.resolved:
        // A scan in one of these states normally carries a diagnosis and is
        // routed elsewhere. If it reaches here the result row is missing, so
        // say that plainly rather than showing a stale "analyzing".
        return _Outcome(
          AppBanner.info(
            title: context.tr('scan_no_result_title'),
            message: context.tr('scan_no_result_msg'),
          ),
        );
    }
  }
}

class _Outcome {
  final Widget banner;

  const _Outcome(this.banner);
}

// =============================================================================
// Crop and capture time
// =============================================================================

class _CropRow extends StatelessWidget {
  final String cropId;
  final DateTime capturedAt;

  const _CropRow({required this.cropId, required this.capturedAt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = CropVisuals.forCrop(cropId);

    return AppCard(
      child: Row(
        children: [
          Icon(visual.icon, size: 20, color: visual.color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _titleCase(cropId) ?? context.tr('unknown_disease'),
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(
            Icons.schedule_rounded,
            size: 14,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _relativeDate(context, capturedAt),
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

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

// =============================================================================
// Image
// =============================================================================

class _ScanImage extends StatelessWidget {
  final String path;

  const _ScanImage({required this.path});

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) {
      return const ColoredBox(
        color: AppColors.surfaceVariant,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 40,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }
    return Image.file(
      file,
      fit: BoxFit.cover,
      // Decode at display width, not the camera's full sensor resolution.
      cacheWidth: (MediaQuery.sizeOf(context).width *
              MediaQuery.devicePixelRatioOf(context))
          .round(),
      errorBuilder: (_, _, _) => const ColoredBox(
        color: AppColors.surfaceVariant,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
