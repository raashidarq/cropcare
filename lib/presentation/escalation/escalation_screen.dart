// lib/presentation/escalation/escalation_screen.dart
//
// Screen to review diagnosis details and share leaf photo + notes with an agronomist on WhatsApp.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/escalation/escalation_cubit.dart';
import '../../application/escalation/escalation_state.dart';
import '../../domain/entities/diagnosis.dart';
import '../../domain/entities/scan.dart';
import '../../domain/usecases/escalation/create_escalation_use_case.dart';
import '../onboarding/localization/localization_provider.dart';

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
    final isLowConfidence = widget.diagnosis.confidence < 0.80 ||
        widget.diagnosis.resultState == DiagnosisResultState.lowConfidence;
    final file = File(widget.scan.imageLocalPath);
    final hasImage = file.existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('escalation_title')),
        elevation: 0,
      ),
      body: BlocConsumer<EscalationCubit, EscalationState>(
        listener: (context, state) {
          if (state is EscalationSharedSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('WhatsApp share opened successfully.'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is EscalationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Share error: ${state.error}'),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Subtitle / Intro ─────────────────────────────────────
                  Text(
                    context.tr('escalation_subtitle'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Image Preview + Quick Metadata ───────────────────────
                  Card(
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasImage)
                          SizedBox(
                            height: 200,
                            width: double.infinity,
                            child: Image.file(
                              file,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            height: 160,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: Icon(Icons.image_outlined, size: 64),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Chip(
                                    avatar: const Icon(Icons.grass, size: 16),
                                    label: Text(
                                      widget.scan.cropId.toUpperCase(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    '${(widget.diagnosis.confidence * 100).toStringAsFixed(1)}% Match',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isLowConfidence
                                          ? Colors.orange.shade800
                                          : Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatDiseaseName(widget.diagnosis.diseaseId),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Low Confidence Advisory Banner (if < 80%) ────────────
                  if (isLowConfidence) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
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
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Farmer Observations & Notes ──────────────────────────
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.edit_note,
                                  color: theme.colorScheme.primary, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                context.tr('farmer_notes_label'),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: context.tr('farmer_notes_hint'),
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── WhatsApp Share Action Button ─────────────────────────
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      key: const Key('whatsapp_share_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // WhatsApp green
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: state is EscalationSharing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share, color: Colors.white),
                      label: Text(
                        context.tr('share_whatsapp_btn'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: state is EscalationSharing
                          ? null
                          : () {
                              context.read<EscalationCubit>().shareViaWhatsApp(
                                    scan: widget.scan,
                                    diagnosis: widget.diagnosis,
                                    farmerNotes: _notesController.text.trim(),
                                  );
                            },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
