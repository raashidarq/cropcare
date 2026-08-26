// lib/presentation/escalation/escalation_screen.dart
//
// Send this scan to someone who knows more — an agronomist, an extension
// officer, a neighbour who has grown this crop for thirty years.
//
// What changed and why:
//
//  * A disclaimer now leads the screen. This is the one place in the app where
//    an automated guess leaves the app and reaches a *second person*, who did
//    not see the caveats on the result screen and may reasonably assume the
//    app is telling them something it verified. The whole design posture of
//    the app (TD-014) collapses if the message arrives sounding authoritative,
//    so the framing travels with it.
//  * The primary button said "WhatsApp" but calls the OS share sheet, which
//    offers whatever the phone has. And a third button, "Share via other
//    apps", called the *identical* method. One honest action replaces two.
//  * It was un-tokenised throughout — raw `Card`, `BorderRadius.circular`,
//    `colorScheme.*`, `TextStyle(fontSize:)`, and translucent hint text.
//  * `cropId.toUpperCase()` — uppercase does not exist in Sinhala or Tamil.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/escalation/escalation_cubit.dart';
import '../../application/escalation/escalation_state.dart';
import '../../core/constants/crop_visuals.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/diagnosis.dart';
import '../../domain/entities/scan.dart';
import '../../domain/usecases/escalation/create_escalation_use_case.dart';
import '../onboarding/localization/localization_provider.dart';
import '../shared/widgets/app_components.dart';

class EscalationScreen extends StatelessWidget {
  final Scan scan;
  final Diagnosis diagnosis;
  final String? initialNotes;
  final CreateEscalationUseCase createEscalationUseCase;

  const EscalationScreen({
    super.key,
    required this.scan,
    required this.diagnosis,
    this.initialNotes,
    required this.createEscalationUseCase,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EscalationCubit>(
      create: (_) => EscalationCubit(
        createEscalationUseCase: createEscalationUseCase,
      ),
      child: _EscalationView(
        scan: scan,
        diagnosis: diagnosis,
        initialNotes: initialNotes,
      ),
    );
  }
}

class _EscalationView extends StatefulWidget {
  final Scan scan;
  final Diagnosis diagnosis;
  final String? initialNotes;

  const _EscalationView({
    required this.scan,
    required this.diagnosis,
    this.initialNotes,
  });

  @override
  State<_EscalationView> createState() => _EscalationViewState();
}

class _EscalationViewState extends State<_EscalationView> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _copySummary(BuildContext context) {
    final text = context.read<EscalationCubit>().formatEscalationText(
          scan: widget.scan,
          diagnosis: widget.diagnosis,
          farmerNotes: _notesController.text.trim(),
        );
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('summary_copied')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _share(BuildContext context) {
    context.read<EscalationCubit>().shareViaWhatsApp(
          scan: widget.scan,
          diagnosis: widget.diagnosis,
          farmerNotes: _notesController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowConfidence = widget.diagnosis.confidence < 0.80 ||
        widget.diagnosis.resultState == DiagnosisResultState.lowConfidence;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('escalation_title')),
        elevation: 0,
      ),
      body: BlocConsumer<EscalationCubit, EscalationState>(
        listener: (context, state) {
          if (state is EscalationSharedSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('whatsapp_share_opened'))),
            );
          } else if (state is EscalationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                // The raw error is deliberately not shown: it is an
                // untranslated Dart exception string.
                content: Text(context.tr('share_failed')),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final sharing = state is EscalationSharing;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // The message is about to leave the app and reach a
                        // person who never saw the result screen. It has to
                        // arrive labelled as a guess.
                        AppBanner.aiDisclaimer(
                          title: context.tr('escalation_disclaimer_title'),
                          message: isLowConfidence
                              ? context.tr('escalation_disclaimer_unsure')
                              : context.tr('escalation_disclaimer_msg'),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        _SharePreview(
                          scan: widget.scan,
                          diagnosis: widget.diagnosis,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        Text(
                          context.tr('farmer_notes_label'),
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          context.tr('farmer_notes_help'),
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.smPlus),
                        TextField(
                          key: const Key('escalation_notes_field'),
                          controller: _notesController,
                          maxLines: 4,
                          minLines: 3,
                          decoration: InputDecoration(
                            hintText: context.tr('farmer_notes_hint'),
                            hintStyle: theme.textTheme.bodySmall,
                            border: const OutlineInputBorder(
                              borderRadius: AppRadius.md,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.smPlus,
                              vertical: AppSpacing.sm,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                _ShareActions(
                  sharing: sharing,
                  onShare: () => _share(context),
                  onCopy: () => _copySummary(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// What will be sent
// =============================================================================

/// Shows the farmer exactly what leaves their phone.
///
/// Previously a raised card wrapping a 200px image and a second padded block
/// of chips. It is a preview, not the subject of the screen, so it is now one
/// flat row.
class _SharePreview extends StatelessWidget {
  final Scan scan;
  final Diagnosis diagnosis;

  const _SharePreview({required this.scan, required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = CropVisuals.forCrop(scan.cropId);
    final file = File(scan.imageLocalPath);
    final percent = (diagnosis.confidence * 100).toStringAsFixed(0);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppRadius.md,
            child: SizedBox(
              width: 84,
              height: 84,
              child: file.existsSync()
                  ? Image.file(
                      file,
                      fit: BoxFit.cover,
                      cacheWidth: 252,
                      errorBuilder: (_, _, _) => _ImageFallback(visual: visual),
                    )
                  : _ImageFallback(visual: visual),
            ),
          ),
          const SizedBox(width: AppSpacing.smPlus),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('escalation_will_send'),
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _formatDiseaseName(diagnosis.diseaseId) ??
                      context.tr('unknown_disease'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${context.tr('confidence_percent').replaceFirst('{percent}', percent)}'
                  '${diagnosis.severity != null ? ' · ${context.tr('severity_label')}: ${diagnosis.severity}' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final CropVisual visual;

  const _ImageFallback({required this.visual});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceVariant,
      child: Center(child: Icon(visual.icon, color: visual.color)),
    );
  }
}

String? _formatDiseaseName(String? id) {
  if (id == null || id.isEmpty) return null;
  return id
      .replaceAll('_', ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

// =============================================================================
// Actions
// =============================================================================

/// One share, one copy.
///
/// There used to be three buttons: a green "WhatsApp" one, a copy button, and
/// "Share via other apps" — which called exactly the same method as the first.
/// The share sheet already offers every app on the phone, so the WhatsApp
/// branding promised a specific destination the code never guaranteed.
class _ShareActions extends StatelessWidget {
  final bool sharing;
  final VoidCallback onShare;
  final VoidCallback onCopy;

  const _ShareActions({
    required this.sharing,
    required this.onShare,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.smPlus,
            AppSpacing.md,
            AppSpacing.smPlus,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: AppSpacing.minTouchTarget,
                child: ElevatedButton.icon(
                  key: const Key('whatsapp_share_button'),
                  icon: sharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Icon(Icons.share_rounded),
                  label: Text(context.tr('share_with_expert_btn')),
                  onPressed: sharing ? null : onShare,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  key: const Key('copy_escalation_text_button'),
                  icon: const Icon(Icons.copy_all_rounded, size: 18),
                  label: Text(context.tr('copy_summary_btn')),
                  onPressed: onCopy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
