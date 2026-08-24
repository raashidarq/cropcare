// lib/presentation/diagnosis/diagnosis_result_screen.dart
//
// Displays ML inference results and AI-powered treatment guidance.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/diagnosis/diagnosis_cubit.dart';
import '../../application/diagnosis/diagnosis_state.dart';
import '../../data/local/database/app_database.dart';
import '../../data/repositories/escalation_repository_impl.dart';
import '../../data/repositories/scan_repository_impl.dart';
import '../../domain/entities/diagnosis.dart';
import '../../domain/entities/scan.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/usecases/diagnosis/resolve_treatment_use_case.dart';
import '../../domain/usecases/escalation/create_escalation_use_case.dart';
import '../escalation/escalation_screen.dart';
import '../onboarding/localization/localization_provider.dart';

class DiagnosisResultScreen extends StatelessWidget {
  final Scan scan;
  final Diagnosis diagnosis;
  final ResolveTreatmentUseCase? resolveTreatmentUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;

  const DiagnosisResultScreen({
    super.key,
    required this.scan,
    required this.diagnosis,
    this.resolveTreatmentUseCase,
    this.createEscalationUseCase,
  });

  @override
  Widget build(BuildContext context) {
    if (resolveTreatmentUseCase != null) {
      return BlocProvider<DiagnosisCubit>(
        create: (_) => DiagnosisCubit(
          resolveTreatmentUseCase: resolveTreatmentUseCase!,
        )..checkDiagnosis(diagnosis),
        child: _DiagnosisResultView(
          scan: scan,
          diagnosis: diagnosis,
          createEscalationUseCase: createEscalationUseCase,
        ),
      );
    }

    return _DiagnosisResultView(
      scan: scan,
      diagnosis: diagnosis,
      createEscalationUseCase: createEscalationUseCase,
    );
  }
}

class _DiagnosisResultView extends StatefulWidget {
  final Scan scan;
  final Diagnosis diagnosis;
  final CreateEscalationUseCase? createEscalationUseCase;

  const _DiagnosisResultView({
    required this.scan,
    required this.diagnosis,
    this.createEscalationUseCase,
  });

  @override
  State<_DiagnosisResultView> createState() => _DiagnosisResultViewState();
}

class _DiagnosisResultViewState extends State<_DiagnosisResultView> {
  final TextEditingController _observationsController = TextEditingController();
  bool _hasAutoFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasAutoFetched &&
        !widget.diagnosis.isHealthy &&
        widget.diagnosis.diseaseId != null) {
      _hasAutoFetched = true;
      _fetchTreatment(context);
    }
  }

  @override
  void dispose() {
    _observationsController.dispose();
    super.dispose();
  }

  void _fetchTreatment(BuildContext context) {
    final languageCode =
        LocalizationProvider.of(context)?.languageCode ?? 'en';
    final cubit = context.read<DiagnosisCubit?>();
    if (cubit == null) return;

    cubit.fetchTreatmentGuidance(
      diagnosisId: widget.diagnosis.id,
      cropId: widget.scan.cropId,
      diseaseId: widget.diagnosis.diseaseId ?? 'unknown',
      confidence: widget.diagnosis.confidence,
      severity: widget.diagnosis.severity,
      languageCode: languageCode,
      userObservations: _observationsController.text.trim().isNotEmpty
          ? _observationsController.text.trim()
          : null,
    );
  }

  void _navigateToEscalation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EscalationScreen(
          scan: widget.scan,
          diagnosis: widget.diagnosis,
          initialNotes: _observationsController.text.trim().isNotEmpty
              ? _observationsController.text.trim()
              : null,
          createEscalationUseCase: widget.createEscalationUseCase ??
              CreateEscalationUseCase(
                escalationRepository: EscalationRepositoryImpl(AppDatabase()),
                scanRepository: ScanRepositoryImpl(AppDatabase()),
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHealthy = widget.diagnosis.isHealthy;
    final isLowConfidence = !isHealthy &&
        (widget.diagnosis.confidence < 0.80 ||
            widget.diagnosis.resultState == DiagnosisResultState.lowConfidence);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('diagnosis_result_title')),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Classification Result Header Card ─────────────────────
              _HeaderCard(
                scan: widget.scan,
                diagnosis: widget.diagnosis,
              ),
              const SizedBox(height: 16),

              // ── 2. Low Confidence Advisory Banner (< 80%) ───────────────
              if (isLowConfidence) ...[
                _LowConfidenceBanner(
                  onEscalate: () => _navigateToEscalation(context),
                ),
                const SizedBox(height: 16),
              ],

              // ── 3. AI Disclaimer ─────────────────────────────────────────
              _AiDisclaimerBanner(),
              const SizedBox(height: 20),

              // ── 4. Branching: Healthy vs Disease / Treatment ──────────────
              if (isHealthy) ...[
                _HealthyCard(),
                const SizedBox(height: 24),
              ] else if (widget.diagnosis.diseaseId != null) ...[
                // Observations Input Card (Optional)
                _ObservationsCard(
                  controller: _observationsController,
                  onSubmit: () => _fetchTreatment(context),
                ),
                const SizedBox(height: 20),

                // Treatment Guidance Section (BlocBuilder)
                _TreatmentGuidanceSection(
                  onRetry: () => _fetchTreatment(context),
                ),
                const SizedBox(height: 24),
              ],

              // ── 5. Bottom Action Buttons ──────────────────────────────────
              _BottomActions(
                onScanAgain: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                onConsultExpert: () => _navigateToEscalation(context),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _LowConfidenceBanner extends StatelessWidget {
  final VoidCallback onEscalate;

  const _LowConfidenceBanner({required this.onEscalate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.orange.shade900, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('low_confidence_advisory'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onEscalate,
              icon: const Icon(Icons.share, size: 16, color: Color(0xFF25D366)),
              label: Text(
                context.tr('get_expert_help'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Header Card — ML Output & Metadata
// =============================================================================

class _HeaderCard extends StatelessWidget {
  final Scan scan;
  final Diagnosis diagnosis;

  const _HeaderCard({
    required this.scan,
    required this.diagnosis,
  });

  String _formatDiseaseName(String? diseaseId) {
    if (diseaseId == null) return 'Unknown Plant Issue';
    return diseaseId
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHealthy = diagnosis.isHealthy;
    final diseaseName = _formatDiseaseName(diagnosis.diseaseId);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ResultBadge(resultState: diagnosis.resultState),
                Chip(
                  avatar: const Icon(Icons.grass, size: 16),
                  label: Text(
                    scan.cropId.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              isHealthy ? 'Healthy Plant' : context.tr('disease_detected'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              diseaseName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isHealthy ? Colors.green.shade700 : theme.colorScheme.error,
              ),
            ),
            const Divider(height: 28),

            Row(
              children: [
                Expanded(
                  child: _MetaChip(
                    icon: Icons.analytics_outlined,
                    label: context.tr('confidence'),
                    value: '${(diagnosis.confidence * 100).toStringAsFixed(1)}%',
                    color: Colors.blue.shade700,
                  ),
                ),
                if (diagnosis.severity != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetaChip(
                      icon: Icons.warning_amber_rounded,
                      label: context.tr('severity'),
                      value: diagnosis.severity!.toUpperCase(),
                      color: _getSeverityColor(diagnosis.severity),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return Colors.red.shade700;
      case 'moderate':
        return Colors.orange.shade800;
      case 'low':
        return Colors.amber.shade800;
      default:
        return Colors.grey.shade700;
    }
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  final DiagnosisResultState resultState;

  const _ResultBadge({required this.resultState});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (resultState) {
      case DiagnosisResultState.confident:
        label = 'Confident AI Match';
        color = Colors.green;
        break;
      case DiagnosisResultState.lowConfidence:
        label = 'Low Confidence';
        color = Colors.orange;
        break;
      case DiagnosisResultState.unsupported:
        label = 'Crop Not Supported';
        color = Colors.grey;
        break;
      case DiagnosisResultState.analysisFailed:
        label = 'Analysis Failed';
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

// =============================================================================
// AI Disclaimer
// =============================================================================

class _AiDisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.amber.shade900),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr('ai_disclaimer'),
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber.shade900,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Healthy Confirmation Card
// =============================================================================

class _HealthyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.check_circle, color: Colors.green.shade800, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                context.tr('healthy_crop_msg'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Observations Input Card (Optional)
// =============================================================================

class _ObservationsCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _ObservationsCard({
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note_outlined,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  context.tr('treatment_observations_label'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: context.tr('treatment_observations_hint'),
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text(context.tr('get_treatment_btn')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Treatment Guidance Section
// =============================================================================

class _TreatmentGuidanceSection extends StatelessWidget {
  final VoidCallback onRetry;

  const _TreatmentGuidanceSection({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<DiagnosisCubit?>();
    if (cubit == null) return const SizedBox.shrink();

    final state = cubit.state;

    if (state is DiagnosisTreatmentLoading) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 20.0),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                context.tr('fetching_treatment'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (state is DiagnosisTreatmentError) {
      return Card(
        elevation: 2,
        color: Colors.amber.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.amber.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wifi_off_rounded,
                      color: Colors.amber.shade900, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr('offline_connection_msg'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(context.tr('retry_btn')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state is DiagnosisTreatmentLoaded) {
      return _TreatmentLoadedCard(treatment: state.treatment);
    }

    return const SizedBox.shrink();
  }
}

class _TreatmentLoadedCard extends StatelessWidget {
  final TreatmentResponse treatment;

  const _TreatmentLoadedCard({required this.treatment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Guidance Title & Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    context.tr('treatment_guidance_title'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 14, color: Colors.purple.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Gemini',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary
            if (treatment.summary.isNotEmpty) ...[
              _GuidanceBlock(
                title: context.tr('treatment_summary'),
                content: treatment.summary,
                icon: Icons.article_outlined,
                iconColor: Colors.blue.shade700,
                backgroundColor: Colors.blue.shade50.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 14),
            ],

            // What to Do
            if (treatment.whatToDo.isNotEmpty) ...[
              _GuidanceBlock(
                title: context.tr('treatment_what_to_do'),
                content: treatment.whatToDo,
                icon: Icons.check_circle_outline,
                iconColor: Colors.green.shade700,
                backgroundColor: Colors.green.shade50.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 14),
            ],

            // What to Avoid
            if (treatment.whatToAvoid.isNotEmpty) ...[
              _GuidanceBlock(
                title: context.tr('treatment_what_to_avoid'),
                content: treatment.whatToAvoid,
                icon: Icons.cancel_outlined,
                iconColor: Colors.red.shade700,
                backgroundColor: Colors.red.shade50.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 14),
            ],

            // Recheck After Days Badge
            if (treatment.recheckAfterDays != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: theme.colorScheme.secondary),
                    const SizedBox(width: 10),
                    Text(
                      '${context.tr('recheck_after_days')} ${treatment.recheckAfterDays} ${context.tr('days')}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuidanceBlock extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const _GuidanceBlock({
    required this.title,
    required this.content,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Bottom Actions
// =============================================================================

class _BottomActions extends StatelessWidget {
  final VoidCallback onScanAgain;
  final VoidCallback onConsultExpert;

  const _BottomActions({
    required this.onScanAgain,
    required this.onConsultExpert,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            key: const Key('diagnosis_scan_again_button'),
            icon: const Icon(Icons.camera_alt),
            label: Text(
              context.tr('scan_again'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: onScanAgain,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.support_agent),
            label: Text(context.tr('get_expert_help')),
            onPressed: onConsultExpert,
          ),
        ),
      ],
    );
  }
}
