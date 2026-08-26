// lib/presentation/diagnosis/diagnosis_result_screen.dart
//
// Displays ML inference results and AI-powered treatment guidance.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/diagnosis/diagnosis_cubit.dart';
import '../../application/settings/accessibility_cubit.dart';
import '../../application/diagnosis/diagnosis_state.dart';
import '../../core/constants/crop_visuals.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_haptics.dart';
import '../../data/local/database/app_database.dart';
import '../../data/local/tts/text_to_speech_service.dart';
import '../../data/repositories/escalation_repository_impl.dart';
import '../../data/repositories/scan_repository_impl.dart';
import '../../domain/entities/diagnosis.dart';
import '../../domain/entities/disease_explanation.dart';
import '../../domain/entities/scan.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/usecases/diagnosis/get_disease_explanation_use_case.dart';
import '../../domain/usecases/diagnosis/resolve_treatment_use_case.dart';
import '../../domain/usecases/escalation/create_escalation_use_case.dart';
import '../escalation/escalation_screen.dart';
import '../onboarding/localization/localization_provider.dart';
import '../shared/widgets/app_components.dart';

class DiagnosisResultScreen extends StatelessWidget {
  final Scan scan;
  final Diagnosis diagnosis;
  final ResolveTreatmentUseCase? resolveTreatmentUseCase;
  final GetDiseaseExplanationUseCase? getDiseaseExplanationUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;
  final TtsService? ttsService;

  const DiagnosisResultScreen({
    super.key,
    required this.scan,
    required this.diagnosis,
    this.resolveTreatmentUseCase,
    this.getDiseaseExplanationUseCase,
    this.createEscalationUseCase,
    this.ttsService,
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
          getDiseaseExplanationUseCase: getDiseaseExplanationUseCase,
          createEscalationUseCase: createEscalationUseCase,
          ttsService: ttsService,
        ),
      );
    }

    return _DiagnosisResultView(
      scan: scan,
      diagnosis: diagnosis,
      getDiseaseExplanationUseCase: getDiseaseExplanationUseCase,
      createEscalationUseCase: createEscalationUseCase,
      ttsService: ttsService,
    );
  }
}

class _DiagnosisResultView extends StatefulWidget {
  final Scan scan;
  final Diagnosis diagnosis;
  final GetDiseaseExplanationUseCase? getDiseaseExplanationUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;
  final TtsService? ttsService;

  const _DiagnosisResultView({
    required this.scan,
    required this.diagnosis,
    this.getDiseaseExplanationUseCase,
    this.createEscalationUseCase,
    this.ttsService,
  });

  @override
  State<_DiagnosisResultView> createState() => _DiagnosisResultViewState();
}

class _DiagnosisResultViewState extends State<_DiagnosisResultView> {
  final TextEditingController _observationsController = TextEditingController();
  late final TtsService _ttsService;

  /// Offline explanation content, loaded once on open. A Future rather than
  /// cubit state because it is a single local read with no transitions worth
  /// modelling, and it must not block or interact with treatment fetching.
  Future<DiseaseExplanation?>? _explanationFuture;
  bool _explanationRequested = false;

  @override
  void initState() {
    super.initState();
    _ttsService = widget.ttsService ?? TextToSpeechService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Treatment guidance is NO LONGER fetched automatically. It costs a
    // network round trip and, on a metered rural connection, a farmer who
    // only wanted to know what the plant has should not pay for advice they
    // did not ask for. It is now behind an explicit button.

    if (_explanationRequested) return;
    _explanationRequested = true;

    final useCase = widget.getDiseaseExplanationUseCase;
    final diseaseId = widget.diagnosis.diseaseId;
    if (useCase == null || diseaseId == null) return;

    final languageCode =
        LocalizationProvider.of(context)?.languageCode ?? 'en';
    setState(() {
      _explanationFuture = useCase(
        diseaseId: diseaseId,
        languageCode: languageCode,
      );
    });
  }

  @override
  void dispose() {
    _ttsService.dispose();
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

  // Fallback wiring, used only when this screen is constructed without an
  // injected use case (tests, or a direct push). main.dart owns the real
  // AppDatabase and threads the use case down in normal navigation.
  //
  // These are static and lazy on purpose: the previous code constructed
  // `AppDatabase()` inline — twice in one expression — on every navigation
  // to escalation, and never closed them. Each one opens a fresh background
  // SQLite connection, so repeated scanning leaked connections and risked
  // "database is locked" contention with the app's real connection (and with
  // the background sync isolate). Capped at one shared instance instead.
  static AppDatabase? _fallbackDb;
  static CreateEscalationUseCase? _fallbackUseCase;

  static CreateEscalationUseCase _fallbackEscalationUseCase() {
    final db = _fallbackDb ??= AppDatabase();
    return _fallbackUseCase ??= CreateEscalationUseCase(
      escalationRepository: EscalationRepositoryImpl(db),
      scanRepository: ScanRepositoryImpl(db),
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
          createEscalationUseCase:
              widget.createEscalationUseCase ?? _fallbackEscalationUseCase(),
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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. The photo, the verdict, the confidence ────────────────
              _ResultHero(scan: widget.scan, diagnosis: widget.diagnosis),
              const SizedBox(height: AppSpacing.md),

              // ── 2. Hedging comes BEFORE the advice ───────────────────────
              // A farmer may act on the first thing they read, so any reason
              // to doubt the result is placed above the treatment guidance
              // rather than below it.
              if (isLowConfidence) ...[
                _LowConfidenceBanner(
                  onEscalate: () => _navigateToEscalation(context),
                ),
                const SizedBox(height: AppSpacing.smPlus),
              ],
              const _AiDisclaimerBanner(),
              const SizedBox(height: AppSpacing.lg),

              // ── 3. Understanding the result (offline) ────────────────────
              // Placed before treatment: what this is, and whether to
              // believe it, comes before what to do about it.
              if (_explanationFuture != null) ...[
                _ExplanationSection(future: _explanationFuture!),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ── 4. Healthy vs disease ────────────────────────────────────
              if (isHealthy) ...[
                const _HealthyCard(),
                const SizedBox(height: AppSpacing.lg),
              ] else if (widget.diagnosis.diseaseId != null) ...[
                _ObservationsCard(
                  controller: _observationsController,
                ),
                const SizedBox(height: AppSpacing.md),
                _TreatmentGuidanceSection(
                  ttsService: _ttsService,
                  onFetch: () => _fetchTreatment(context),
                ),
                const SizedBox(height: AppSpacing.md),
                const _ChatWithResultPlaceholder(),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ── 4. Actions ───────────────────────────────────────────────
              _BottomActions(
                onScanAgain: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                onConsultExpert: () => _navigateToEscalation(context),
              ),
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
    return AppBanner.warning(
      title: context.tr('low_confidence_title'),
      message: context.tr('low_confidence_msg'),
      actionLabel: context.tr('get_expert_help'),
      onAction: onEscalate,
    );
  }
}

// =============================================================================
// Result hero — the photo, the verdict, and how much to trust it
// =============================================================================

/// Leads with the farmer's own photo.
///
/// The previous header was a text-only card that opened with a green
/// "Confident AI Match" badge. That is the wrong emphasis for a closed-set
/// classifier that cannot tell it has been shown something it was never
/// trained on: it presented a guess with the confidence of a fact. This
/// version shows the photo that produced the result, states the verdict
/// plainly, and puts the confidence figure next to it rather than leading
/// with a reassuring badge.
class _ResultHero extends StatelessWidget {
  final Scan scan;
  final Diagnosis diagnosis;

  const _ResultHero({required this.scan, required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageCode = LocalizationProvider.of(context)?.languageCode ?? 'en';
    final isHealthy = diagnosis.isHealthy;
    final visual = CropVisuals.forCrop(scan.cropId);

    final title = isHealthy
        ? context.tr('result_healthy_title')
        : (_formatDiseaseName(diagnosis.diseaseId) ??
            context.tr('unknown_disease'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppRadius.lg,
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _ScanImage(path: scan.imageLocalPath),
                // Bottom-up scrim so the overlaid crop chip stays readable
                // whatever the photo happens to look like.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [Color(0xCC000000), Color(0x00000000)],
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.smPlus,
                  bottom: AppSpacing.smPlus,
                  right: AppSpacing.smPlus,
                  child: Row(
                    children: [
                      Icon(visual.icon, size: 18, color: Colors.white),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          _cropLabel(context, languageCode),
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          isHealthy
              ? context.tr('result_healthy_msg')
              : context.tr('disease_detected'),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: isHealthy ? AppColors.success : AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _stateChip(context),
            if (diagnosis.severity != null)
              AppStatusChip.severity(
                diagnosis.severity,
                '${context.tr('severity_label')}: ${diagnosis.severity!}',
              ),
          ],
        ),
        if (!isHealthy) ...[
          const SizedBox(height: AppSpacing.md),
          AppConfidenceMeter(
            confidence: diagnosis.confidence,
            label: context.tr('confidence_label'),
          ),
        ],
      ],
    );
  }

  String _cropLabel(BuildContext context, String languageCode) {
    final id = scan.cropId;
    if (id.isEmpty || id == 'unknown') return context.tr('unknown_disease');
    return _formatDiseaseName(id) ?? id;
  }

  Widget _stateChip(BuildContext context) {
    switch (diagnosis.resultState) {
      case DiagnosisResultState.confident:
        return AppStatusChip(
          icon: Icons.check_circle_outline_rounded,
          // "Likely match", not "Confident AI Match" — the model cannot
          // distinguish an unfamiliar input from a familiar one, so the
          // wording should not promise more than it can deliver.
          label: context.tr('badge_confident'),
          foreground: AppColors.onInfoContainer,
          background: AppColors.infoContainer,
        );
      case DiagnosisResultState.lowConfidence:
        return AppStatusChip(
          icon: Icons.help_outline_rounded,
          label: context.tr('badge_low_confidence'),
          foreground: AppColors.onWarningContainer,
          background: AppColors.warningContainer,
        );
      case DiagnosisResultState.unsupported:
        return AppStatusChip(
          icon: Icons.block_outlined,
          label: context.tr('badge_unsupported'),
          foreground: AppColors.onSurfaceVariant,
          background: AppColors.surfaceVariant,
        );
      case DiagnosisResultState.analysisFailed:
        return AppStatusChip(
          icon: Icons.error_outline_rounded,
          label: context.tr('badge_failed'),
          foreground: AppColors.onErrorContainer,
          background: AppColors.errorContainer,
        );
    }
  }
}

/// `tomato_late_blight` -> `Tomato Late Blight`.
///
/// English-only: a Diagnosis carries a disease *id*, and the localized
/// `name_si` / `name_ta` columns live on the `disease` table, which is not
/// joined into this screen. Worth fixing — disease names are exactly what a
/// Sinhala or Tamil speaker most needs in their own language — but it needs
/// the disease row threaded through the diagnosis read path.
String? _formatDiseaseName(String? id) {
  if (id == null || id.isEmpty) return null;
  return id
      .replaceAll('_', ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

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

// =============================================================================
// AI Disclaimer
// =============================================================================

class _AiDisclaimerBanner extends StatelessWidget {
  const _AiDisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return AppBanner.aiDisclaimer(
      title: context.tr('ai_disclaimer_title'),
      message: context.tr('ai_disclaimer_msg'),
    );
  }
}

// =============================================================================
// Healthy Confirmation Card
// =============================================================================

class _HealthyCard extends StatelessWidget {
  const _HealthyCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      color: AppColors.successContainer,
      borderColor: AppColors.successContainer,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.onSuccess,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              context.tr('healthy_crop_msg'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSuccessContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Observations Input Card (Optional)
// =============================================================================

class _ObservationsCard extends StatelessWidget {
  final TextEditingController controller;

  const _ObservationsCard({required this.controller});

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
            // Speaking is far more realistic than typing here: the keyboard
            // for Sinhala and Tamil is slow, and this is a field where a
            // farmer is holding a phone in one hand. Entry point placed
            // now; implementation is a separate piece of work.
            _VoiceInputPlaceholder(),
          ],
        ),
      ),
    );
  }
}

/// Inert entry point for speaking observations instead of typing them.
class _VoiceInputPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => showComingSoon(context),
      borderRadius: AppRadius.md,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_none_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.smPlus),
            Expanded(
              child: Text(
                context.tr('speak_observations'),
                style: theme.textTheme.bodySmall,
              ),
            ),
            const ComingSoonPill(),
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
  final VoidCallback onFetch;
  final TtsService? ttsService;

  const _TreatmentGuidanceSection({
    required this.onFetch,
    this.ttsService,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<DiagnosisCubit?>();
    if (cubit == null) return const SizedBox.shrink();

    final state = cubit.state;

    // Nothing requested yet: offer the action rather than firing it. The
    // request tries the online source first and only drops to the on-device
    // guidelines if that fails (see TreatmentRepositoryImpl), so it can cost
    // mobile data — that should be the farmer's decision, not a side effect
    // of opening the screen.
    if (state is DiagnosisInitial || state is DiagnosisHealthy) {
      return _TreatmentPrompt(onFetch: onFetch);
    }

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
      return AppBanner(
        icon: Icons.wifi_off_rounded,
        message: context.tr('offline_connection_msg'),
        foreground: AppColors.onWarningContainer,
        background: AppColors.warningContainer,
        actionLabel: context.tr('retry_btn'),
        onAction: onFetch,
      );
    }

    if (state is DiagnosisTreatmentLoaded) {
      AppHaptics.resultReady(context);
      // Honours the "read results aloud automatically" setting, which
      // previously existed in the UI but was wired to nothing. Opt-in and
      // off by default — unexpected audio is worse than none.
      _maybeAutoRead(context, state.treatment);
      return _TreatmentLoadedCard(
        treatment: state.treatment,
        ttsService: ttsService,
      );
    }

    return const SizedBox.shrink();
  }
}

/// Speaks the guidance once, if auto-read is enabled. Guarded by a set of
/// already-spoken treatments so a rebuild does not restart playback.
final Set<String> _autoReadFired = <String>{};

void _maybeAutoRead(BuildContext context, TreatmentResponse treatment) {
  final AccessibilityCubit cubit;
  try {
    cubit = context.read<AccessibilityCubit>();
  } catch (_) {
    return;
  }
  if (!cubit.state.autoReadDiagnosis) return;

  final signature = '${treatment.interpretationId}|${treatment.summary}';
  if (!_autoReadFired.add(signature)) return;

  final section = context.findAncestorWidgetOfExactType<_TreatmentGuidanceSection>();
  final tts = section?.ttsService;
  if (tts == null) return;

  final lang = LocalizationProvider.of(context)?.languageCode ?? 'en';
  final text =
      '${treatment.summary}. ${context.tr('treatment_what_to_do')}: ${treatment.whatToDo}. ${context.tr('treatment_what_to_avoid')}: ${treatment.whatToAvoid}.';

  WidgetsBinding.instance.addPostFrameCallback((_) {
    tts.speak(text: text, languageCode: lang, speechRate: cubit.state.speechRate);
  });
}

/// Reads the user's chosen playback pace, falling back to the default when
/// the accessibility cubit is not in scope (tests, isolated widget use).
double _speechRateOf(BuildContext context) {
  try {
    return context.read<AccessibilityCubit>().state.speechRate;
  } catch (_) {
    return 0.5;
  }
}

class _TreatmentLoadedCard extends StatelessWidget {
  final TreatmentResponse treatment;
  final TtsService? ttsService;

  const _TreatmentLoadedCard({
    required this.treatment,
    this.ttsService,
  });

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
                // Where this advice came from — a live AI call or the
                // on-device fallback guidelines — stated plainly, because it
                // changes how much a farmer should trust the specifics.
                Builder(
                  key: const Key('treatment_source_badge'),
                  builder: (context) {
                    final isAi = treatment.interpretationId != null;
                    final color = isAi
                        ? AppColors.treatmentSourceAi
                        : AppColors.treatmentSourceOffline;
                    return AppStatusChip(
                      icon: isAi
                          ? Icons.auto_awesome
                          : Icons.offline_pin_outlined,
                      label: isAi
                          ? context.tr('treatment_source_ai')
                          : context.tr('treatment_source_offline'),
                      foreground: color,
                      background: AppColors.surfaceVariant,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Read Aloud / TTS Audio Playback Button ──────────────────────
            if (ttsService != null) ...[
              ValueListenableBuilder<bool>(
                valueListenable: ttsService!.isPlaying,
                builder: (context, isPlaying, _) {
                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key('treatment_tts_button'),
                      // Read-aloud matters more here than in most apps: it is
                      // the path through the treatment advice for a farmer
                      // who does not read comfortably. Given full width and
                      // a stateful label rather than a small icon button.
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isPlaying ? AppColors.error : AppColors.primary,
                        side: BorderSide(
                          color:
                              isPlaying ? AppColors.error : AppColors.primary,
                          width: 1.5,
                        ),
                        backgroundColor:
                            isPlaying ? AppColors.errorContainer : null,
                      ),
                      icon: Icon(
                        isPlaying
                            ? Icons.stop_circle_outlined
                            : Icons.volume_up_rounded,
                        size: 20,
                      ),
                      label: Text(
                        isPlaying
                            ? context.tr('stop_reading')
                            : context.tr('read_aloud'),
                      ),
                      onPressed: () {
                        if (isPlaying) {
                          ttsService!.stop();
                        } else {
                          final lang =
                              LocalizationProvider.of(context)?.languageCode ??
                                  'en';
                          final speechText =
                              '${treatment.summary}. ${context.tr('treatment_what_to_do')}: ${treatment.whatToDo}. ${context.tr('treatment_what_to_avoid')}: ${treatment.whatToAvoid}.';
                          ttsService!.speak(
                            text: speechText,
                            languageCode: lang,
                            speechRate: _speechRateOf(context),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
            ],

            // Summary
            if (treatment.summary.isNotEmpty) ...[
              _GuidanceBlock(
                title: context.tr('treatment_summary'),
                content: treatment.summary,
                icon: Icons.article_outlined,
                iconColor: AppColors.info,
                backgroundColor: AppColors.infoContainer,
              ),
              const SizedBox(height: 14),
            ],

            // What to Do
            if (treatment.whatToDo.isNotEmpty) ...[
              _GuidanceBlock(
                title: context.tr('treatment_what_to_do'),
                content: treatment.whatToDo,
                icon: Icons.check_circle_outline,
                iconColor: AppColors.success,
                backgroundColor: AppColors.successContainer,
              ),
              const SizedBox(height: 14),
            ],

            // What to Avoid
            if (treatment.whatToAvoid.isNotEmpty) ...[
              _GuidanceBlock(
                title: context.tr('treatment_what_to_avoid'),
                content: treatment.whatToAvoid,
                icon: Icons.cancel_outlined,
                iconColor: AppColors.error,
                backgroundColor: AppColors.errorContainer,
              ),
              const SizedBox(height: 14),
            ],

            // Recheck After Days Badge
            if (treatment.recheckAfterDays != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.infoContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_available_rounded,
                        size: 18, color: AppColors.info),
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

// =============================================================================
// Offline explanation — "what am I actually looking at?"
// =============================================================================
//
// Reads content shipped with the app rather than fetched, so it is available
// with no connection and costs nothing to show. Content is authored
// separately; this renders whatever is present and stays quiet about what is
// not, field by field.

class _ExplanationSection extends StatelessWidget {
  final Future<DiseaseExplanation?> future;

  const _ExplanationSection({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DiseaseExplanation?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ExplanationSkeleton();
        }

        final explanation = snapshot.data;
        if (explanation == null || explanation.isEmpty) {
          return const _ExplanationUnavailable();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: context.tr('understand_result_title'),
              icon: Icons.menu_book_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (explanation.hasPlantDescription) ...[
              _ExplanationCard(
                icon: Icons.local_florist_outlined,
                title: context.tr('about_this_plant'),
                body: explanation.plantDescription!,
              ),
              const SizedBox(height: AppSpacing.smPlus),
            ],
            if (explanation.hasResultMeaning) ...[
              _ExplanationCard(
                icon: Icons.help_outline_rounded,
                title: context.tr('what_result_suggests'),
                body: explanation.resultMeaning!,
              ),
              const SizedBox(height: AppSpacing.smPlus),
            ],
            if (explanation.hasConfusions)
              _ConfusionCard(
                confusions:
                    explanation.confusions.where((c) => !c.isEmpty).toList(),
              ),
          ],
        );
      },
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _ExplanationCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Look-alike conditions. Deliberately its own card with a cautionary tone:
/// the whole point is to stop a farmer acting on a confident-looking result
/// when something else produces the same spots.
class _ConfusionCard extends StatelessWidget {
  final List<DiseaseConfusion> confusions;

  const _ConfusionCard({required this.confusions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.compare_arrows_rounded,
                size: 20,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.tr('could_be_confused_with'),
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('could_be_confused_with_desc'),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.smPlus),
          for (var i = 0; i < confusions.length; i++) ...[
            if (i > 0) const Divider(height: AppSpacing.lg),
            _ConfusionRow(confusion: confusions[i]),
          ],
        ],
      ),
    );
  }
}

class _ConfusionRow extends StatelessWidget {
  final DiseaseConfusion confusion;

  const _ConfusionRow({required this.confusion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = confusion.label;
    final symptoms = confusion.distinguishingSymptoms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null && label.trim().isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
            ],
          ),
        if (symptoms != null && symptoms.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 14, top: AppSpacing.xs),
            child: Text(symptoms, style: theme.textTheme.bodySmall),
          ),
      ],
    );
  }
}

class _ExplanationSkeleton extends StatelessWidget {
  const _ExplanationSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.smPlus),
          Expanded(
            child: Text(
              context.tr('loading_explanation'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the device holds no explanation content for this disease.
/// Stated plainly rather than hidden, so the absence reads as "not delivered
/// yet" rather than "this screen is broken".
class _ExplanationUnavailable extends StatelessWidget {
  const _ExplanationUnavailable();

  @override
  Widget build(BuildContext context) {
    return AppBanner.info(
      title: context.tr('understand_result_title'),
      message: context.tr('explanation_unavailable_msg'),
    );
  }
}

// =============================================================================
// Treatment prompt — the explicit ask
// =============================================================================

class _TreatmentPrompt extends StatelessWidget {
  final VoidCallback onFetch;

  const _TreatmentPrompt({required this.onFetch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.medical_services_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.tr('treatment_guidance_title'),
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('get_treatment_prompt_desc'),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.smPlus),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('get_treatment_guidance_button'),
              icon: const Icon(Icons.medical_information_outlined),
              label: Text(context.tr('get_treatment_btn')),
              onPressed: onFetch,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Placeholders for features not yet built
// =============================================================================
//
// Both are deliberately inert and visibly marked. They exist so the entry
// point's placement can be reviewed alongside the rest of the screen. The
// implementation briefs live in docs/future/.

class _ChatWithResultPlaceholder extends StatelessWidget {
  const _ChatWithResultPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      color: AppColors.surfaceVariant,
      onTap: () => showComingSoon(context),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.md,
            ),
            child: const Icon(Icons.forum_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        context.tr('chat_with_result_title'),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const ComingSoonPill(),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.tr('chat_with_result_desc'),
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

/// Marks an entry point as not yet functional. Shared by the chat and
/// voice-input placeholders so they read as one class of thing.
class ComingSoonPill extends StatelessWidget {
  const ComingSoonPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.infoContainer,
        borderRadius: AppRadius.full,
      ),
      child: Text(
        context.tr('coming_soon'),
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: AppColors.onInfoContainer),
      ),
    );
  }
}

void showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.tr('coming_soon_msg'))),
  );
}
