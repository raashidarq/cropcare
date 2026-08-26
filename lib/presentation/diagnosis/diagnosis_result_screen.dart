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
import '../../data/local/speech/speech_recognition_service.dart';
import '../../data/local/tts/text_to_speech_service.dart';
import '../../data/repositories/escalation_repository_impl.dart';
import '../../data/repositories/scan_repository_impl.dart';
import '../../domain/entities/diagnosis.dart';
import '../../domain/entities/disease_explanation.dart';
import '../../domain/entities/scan.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/usecases/diagnosis/get_disease_explanation_use_case.dart';
import '../../application/chat/chat_cubit.dart';
import '../../domain/usecases/chat/delete_chat_message_use_case.dart';
import '../../domain/usecases/chat/get_chat_history_use_case.dart';
import '../../domain/usecases/chat/send_chat_message_use_case.dart';
import '../chat/chat_screen.dart';
import '../../domain/usecases/diagnosis/get_local_treatment_guidance_use_case.dart';
import '../../domain/usecases/diagnosis/resolve_treatment_use_case.dart';
import '../../domain/usecases/escalation/create_escalation_use_case.dart';
import '../escalation/escalation_screen.dart';
import '../onboarding/localization/localization_provider.dart';
import '../shared/widgets/app_components.dart';

class DiagnosisResultScreen extends StatelessWidget {
  final Scan scan;
  final Diagnosis diagnosis;
  final ResolveTreatmentUseCase? resolveTreatmentUseCase;
  final GetLocalTreatmentGuidanceUseCase? getLocalTreatmentGuidanceUseCase;
  final GetDiseaseExplanationUseCase? getDiseaseExplanationUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;
  final TtsService? ttsService;
  final SpeechRecognitionService? speechService;
  final GetChatHistoryUseCase? getChatHistoryUseCase;
  final SendChatMessageUseCase? sendChatMessageUseCase;
  final DeleteChatMessageUseCase? deleteChatMessageUseCase;

  const DiagnosisResultScreen({
    super.key,
    required this.scan,
    required this.diagnosis,
    this.resolveTreatmentUseCase,
    this.getLocalTreatmentGuidanceUseCase,
    this.getDiseaseExplanationUseCase,
    this.createEscalationUseCase,
    this.ttsService,
    this.speechService,
    this.getChatHistoryUseCase,
    this.sendChatMessageUseCase,
    this.deleteChatMessageUseCase,
  });

  @override
  Widget build(BuildContext context) {
    if (resolveTreatmentUseCase != null) {
      return BlocProvider<DiagnosisCubit>(
        create: (_) => DiagnosisCubit(
          resolveTreatmentUseCase: resolveTreatmentUseCase!,
          getLocalTreatmentGuidanceUseCase: getLocalTreatmentGuidanceUseCase,
        )..checkDiagnosis(diagnosis),
        child: _DiagnosisResultView(
          scan: scan,
          diagnosis: diagnosis,
          getDiseaseExplanationUseCase: getDiseaseExplanationUseCase,
          createEscalationUseCase: createEscalationUseCase,
          ttsService: ttsService,
          speechService: speechService,
          getChatHistoryUseCase: getChatHistoryUseCase,
          sendChatMessageUseCase: sendChatMessageUseCase,
          deleteChatMessageUseCase: deleteChatMessageUseCase,
        ),
      );
    }

    return _DiagnosisResultView(
      scan: scan,
      diagnosis: diagnosis,
      getDiseaseExplanationUseCase: getDiseaseExplanationUseCase,
      createEscalationUseCase: createEscalationUseCase,
      ttsService: ttsService,
      speechService: speechService,
      getChatHistoryUseCase: getChatHistoryUseCase,
      sendChatMessageUseCase: sendChatMessageUseCase,
      deleteChatMessageUseCase: deleteChatMessageUseCase,
    );
  }
}

class _DiagnosisResultView extends StatefulWidget {
  final Scan scan;
  final Diagnosis diagnosis;
  final GetDiseaseExplanationUseCase? getDiseaseExplanationUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;
  final TtsService? ttsService;
  final SpeechRecognitionService? speechService;
  final GetChatHistoryUseCase? getChatHistoryUseCase;
  final SendChatMessageUseCase? sendChatMessageUseCase;
  final DeleteChatMessageUseCase? deleteChatMessageUseCase;

  const _DiagnosisResultView({
    required this.scan,
    required this.diagnosis,
    this.getDiseaseExplanationUseCase,
    this.createEscalationUseCase,
    this.ttsService,
    this.speechService,
    this.getChatHistoryUseCase,
    this.sendChatMessageUseCase,
    this.deleteChatMessageUseCase,
  });

  @override
  State<_DiagnosisResultView> createState() => _DiagnosisResultViewState();
}

class _DiagnosisResultViewState extends State<_DiagnosisResultView> {
  final TextEditingController _observationsController = TextEditingController();
  late final TtsService _ttsService;
  late final SpeechRecognitionService _speechService;

  /// Offline explanation content, loaded once on open. A Future rather than
  /// cubit state because it is a single local read with no transitions worth
  /// modelling, and it must not block or interact with treatment fetching.
  Future<DiseaseExplanation?>? _explanationFuture;
  bool _explanationRequested = false;

  @override
  void initState() {
    super.initState();
    _ttsService = widget.ttsService ?? TextToSpeechService();
    _speechService =
        widget.speechService ?? DeviceSpeechRecognitionService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_explanationRequested) return;
    _explanationRequested = true;

    final diseaseId = widget.diagnosis.diseaseId;
    if (diseaseId == null) return;

    final languageCode =
        LocalizationProvider.of(context)?.languageCode ?? 'en';

    // The guidance shipped with the app loads immediately. It is a local read:
    // no network, no cost, no waiting, and it is already translated into all
    // three languages for every disease the model can name. A farmer opening
    // this screen wants to know what to do, so the screen tells them.
    //
    // The *online* request stays an explicit action (see `_fetchTreatment`) —
    // it costs mobile data and tailors advice to the farmer's own
    // observations, so it is worth asking for. What changed is the default:
    // it used to be that no guidance appeared at all until you asked.
    final cubit = context.read<DiagnosisCubit?>();
    cubit?.loadLocalGuidance(
      diseaseId: diseaseId,
      languageCode: languageCode,
    );

    final useCase = widget.getDiseaseExplanationUseCase;
    if (useCase == null) return;

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
    _speechService.dispose();
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

  /// Opens the follow-up conversation for this diagnosis.
  ///
  /// A full screen rather than an inline expander: the result screen is
  /// already long, and a conversation needs the height.
  void _openChat(BuildContext context) {
    final getHistory = widget.getChatHistoryUseCase;
    final send = widget.sendChatMessageUseCase;
    if (getHistory == null || send == null) return;

    final languageCode = LocalizationProvider.of(context)?.languageCode ?? 'en';

    // Whatever guidance is currently on screen goes with the question, so the
    // answers cannot contradict what the farmer is looking at.
    final state = context.read<DiagnosisCubit?>()?.state;
    final treatmentSummary =
        state is DiagnosisTreatmentLoaded ? state.treatment.summary : null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          cubit: ChatCubit(
            getChatHistoryUseCase: getHistory,
            sendChatMessageUseCase: send,
            deleteChatMessageUseCase: widget.deleteChatMessageUseCase,
            diagnosis: widget.diagnosis,
            cropId: widget.scan.cropId,
            languageCode: languageCode,
            userObservations: _observationsController.text.trim().isNotEmpty
                ? _observationsController.text.trim()
                : null,
            treatmentSummary: treatmentSummary,
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
                    // 1. The photo, the verdict, the confidence.
                    _ResultHero(
                      scan: widget.scan,
                      diagnosis: widget.diagnosis,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 2. One caveat, not a stack of them.
                    //
                    // Hedging still comes before the advice: a farmer may act
                    // on the first thing they read. But it used to be two
                    // separate banners (low confidence, then the AI
                    // disclaimer) and then, on every real diagnosis, a third
                    // saying the app had no explanation content. Three
                    // consecutive blocks of "do not fully trust this" before
                    // any advice reads as noise and gets scrolled past, which
                    // is the opposite of what a hedge is for.
                    _ResultCaveat(
                      isLowConfidence: isLowConfidence,
                      onEscalate: () => _navigateToEscalation(context),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 3. What to do about it.
                    //
                    // Guidance leads now. The on-device guideline is loaded
                    // when the screen opens, so the answer is already here
                    // rather than behind a button.
                    if (isHealthy) ...[
                      const _HealthyCard(),
                      const SizedBox(height: AppSpacing.lg),
                    ] else if (widget.diagnosis.diseaseId != null) ...[
                      _TreatmentGuidanceSection(
                        ttsService: _ttsService,
                        onFetch: () => _fetchTreatment(context),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 4. What else it might be.
                      //
                      // The honest presentation of a closed-set classifier: it
                      // always names something, so showing the runner-ups and
                      // how close they were turns that weakness into
                      // information the farmer can actually use.
                      _AlternativesCard(diagnosis: widget.diagnosis),

                      // 5. Add detail to improve the advice.
                      //
                      // Below the guidance, not above it. Asking a farmer to
                      // type before they have been told anything is asking
                      // them to pay first; here it reads as "make this
                      // better", which is what it does.
                      _ObservationsCard(
                        controller: _observationsController,
                        onSubmit: () => _fetchTreatment(context),
                        speechService: _speechService,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Follow-up questions. Only offered when the use cases
                      // were threaded through; the entry point is absent
                      // rather than inert if they were not.
                      if (widget.getChatHistoryUseCase != null &&
                          widget.sendChatMessageUseCase != null) ...[
                        _AskAboutResultCard(onTap: () => _openChat(context)),
                        const SizedBox(height: AppSpacing.lg),
                      ] else
                        const SizedBox(height: AppSpacing.sm),
                    ],

                    // 6. Understanding the result, offline.
                    //
                    // Renders nothing at all when no content is stored, which
                    // is currently the case for every disease.
                    if (_explanationFuture != null)
                      _ExplanationSection(future: _explanationFuture!),
                  ],
                ),
              ),
            ),

            // Sticky actions, pinned rather than sitting at the end of a long
            // scroll. "Ask an expert" in particular is what a farmer reaches
            // for when the result does not help, and finding it should not
            // require reading the whole screen first.
            _BottomActions(
              onScanAgain: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              onConsultExpert: () => _navigateToEscalation(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// The single "how much should I trust this?" block.
///
/// Replaces a stack of two banners. When the model is unsure, that is the more
/// urgent thing to say and it absorbs the standing AI disclaimer rather than
/// repeating it underneath — one amber block with one action, instead of two
/// the farmer has to tell apart. When the model is confident, the standing
/// disclaimer stands alone, as before.
class _ResultCaveat extends StatelessWidget {
  final bool isLowConfidence;
  final VoidCallback onEscalate;

  const _ResultCaveat({
    required this.isLowConfidence,
    required this.onEscalate,
  });

  @override
  Widget build(BuildContext context) {
    if (isLowConfidence) {
      return AppBanner.warning(
        title: context.tr('low_confidence_title'),
        message: '${context.tr('low_confidence_msg')} '
            '${context.tr('ai_disclaimer_msg')}',
        actionLabel: context.tr('get_expert_help'),
        onAction: onEscalate,
      );
    }
    return const _AiDisclaimerBanner();
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

/// Optional detail the farmer can add, and the action that uses it.
///
/// This used to sit *above* the treatment guidance with no action of its own:
/// a farmer was asked to type into a box before the app had told them
/// anything, and the text only did something if they later pressed a separate
/// button further down. It now sits below the guidance and carries the button
/// that acts on it, so the box has a visible purpose at the point of asking.
///
/// The mic is the more important of the two inputs. Typing is the worst
/// interaction in this app for its audience — Sinhala and Tamil keyboards are
/// slow, and the farmer is usually one-handed in a field — so speaking is the
/// path this card is really built around. It is offered only when the device
/// can actually transcribe the active language: an English-only mic button
/// would serve exactly the users who least need it.
class _ObservationsCard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final SpeechRecognitionService? speechService;

  const _ObservationsCard({
    required this.controller,
    required this.onSubmit,
    this.speechService,
  });

  @override
  State<_ObservationsCard> createState() => _ObservationsCardState();
}

class _ObservationsCardState extends State<_ObservationsCard> {
  SpeechRecognitionService? _speech;

  /// Null until the check completes; false means "do not offer the mic".
  bool? _speechAvailable;

  /// Text already in the field when recording began. Transcription appends to
  /// it rather than replacing it, so someone can type a little and then speak
  /// the rest without losing what they wrote.
  String _textBeforeListening = '';

  String? _errorKey;

  @override
  void initState() {
    super.initState();
    _speech = widget.speechService;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_speechAvailable != null) return;
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final service = _speech;
    if (service == null) {
      if (mounted) setState(() => _speechAvailable = false);
      return;
    }
    final languageCode = LocalizationProvider.of(context)?.languageCode ?? 'en';
    final available = await service.localeAvailable(languageCode);
    if (!mounted) return;
    setState(() => _speechAvailable = available);
  }

  Future<void> _toggleRecording() async {
    final service = _speech;
    if (service == null) return;

    if (service.isListening.value) {
      await service.stopListening();
      return;
    }

    setState(() => _errorKey = null);
    _textBeforeListening = widget.controller.text.trimRight();
    final languageCode = LocalizationProvider.of(context)?.languageCode ?? 'en';

    try {
      AppHaptics.recordingToggled(context);
      await service.startListening(
        languageCode: languageCode,
        onResult: (words) {
          if (words.isEmpty) return;
          final prefix =
              _textBeforeListening.isEmpty ? '' : '$_textBeforeListening ';
          widget.controller.text = '$prefix$words';
          widget.controller.selection = TextSelection.collapsed(
            offset: widget.controller.text.length,
          );
        },
      );
    } on SpeechUnavailable catch (e) {
      if (!mounted) return;
      setState(() => _errorKey = _messageKeyFor(e.reason));
    }
  }

  static String _messageKeyFor(SpeechUnavailableReason reason) {
    switch (reason) {
      case SpeechUnavailableReason.permissionDenied:
        return 'mic_permission_denied';
      case SpeechUnavailableReason.permissionPermanentlyDenied:
        return 'mic_permission_blocked';
      case SpeechUnavailableReason.unavailableOnDevice:
        return 'mic_unavailable';
      case SpeechUnavailableReason.languageNotInstalled:
        return 'mic_language_missing';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = _speech;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.tr('treatment_observations_label'),
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smPlus),
          TextField(
            controller: widget.controller,
            maxLines: 3,
            minLines: 2,
            // Stays editable after transcription: recognition will get
            // agricultural vocabulary and place names wrong.
            decoration: InputDecoration(
              hintText: context.tr('treatment_observations_hint'),
              hintStyle: theme.textTheme.bodySmall,
              border: const OutlineInputBorder(borderRadius: AppRadius.md),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.smPlus,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
          if (service != null && _speechAvailable == true) ...[
            const SizedBox(height: AppSpacing.smPlus),
            ValueListenableBuilder<bool>(
              valueListenable: service.isListening,
              builder: (context, listening, _) => _RecordButton(
                listening: listening,
                onTap: _toggleRecording,
              ),
            ),
          ],
          if (_errorKey != null) ...[
            const SizedBox(height: AppSpacing.smPlus),
            AppBanner.warning(
              message: context.tr(_errorKey!),
              actionLabel:
                  _errorKey == 'mic_permission_blocked' ? context.tr('open_app_settings') : null,
              onAction: _errorKey == 'mic_permission_blocked'
                  ? () => service?.openAppSettings()
                  : null,
            ),
          ],
          const SizedBox(height: AppSpacing.smPlus),
          SizedBox(
            height: AppSpacing.minTouchTarget,
            child: OutlinedButton.icon(
              key: const Key('refine_guidance_button'),
              icon: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: Text(context.tr('refine_guidance_btn')),
              onPressed: widget.onSubmit,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('refine_guidance_hint'),
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

/// Record / stop control.
///
/// Matched to the read-aloud button so the two read as a pair: same height,
/// same full-width treatment, same "active" colour swap. An explicit stop is
/// always available — silence detection alone is unreliable in wind and field
/// noise.
class _RecordButton extends StatelessWidget {
  final bool listening;
  final VoidCallback onTap;

  const _RecordButton({required this.listening, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.minTouchTarget,
      child: ElevatedButton.icon(
        key: const Key('observations_mic_button'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              listening ? AppColors.error : AppColors.surfaceVariant,
          foregroundColor:
              listening ? AppColors.onError : AppColors.onSurfaceVariant,
          elevation: 0,
        ),
        icon: Icon(listening ? Icons.stop_rounded : Icons.mic_rounded),
        label: Text(
          listening
              ? context.tr('mic_stop')
              : context.tr('speak_observations'),
        ),
        onPressed: onTap,
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
        // Render nothing when there is no content. `disease_explanation` ships
        // empty by design (TD-018), so this section previously rendered an
        // apology on every real diagnosis — a farmer scrolling to the advice
        // passed a banner telling them the app has nothing to say. An absent
        // section is quieter and more honest than a present empty one.
        if (explanation == null || explanation.isEmpty) {
          return const SizedBox.shrink();
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
// Ask about this result
// =============================================================================

/// Entry point into the follow-up conversation.
///
/// Replaces the inert "coming soon" card that used to sit here.
class _AskAboutResultCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AskAboutResultCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppActionTile(
      key: const Key('ask_about_result_card'),
      icon: Icons.forum_outlined,
      title: context.tr('chat_with_result_title'),
      subtitle: context.tr('chat_with_result_desc'),
      onTap: onTap,
    );
  }
}

// =============================================================================
// Other possibilities — the model's runner-up predictions
// =============================================================================
//
// The model is a closed-set 38-class softmax with no rejection option: it
// cannot answer "none of the above", so it always names something (TD-014).
// Showing what else it considered, and how close those were, is the honest
// way to present that. It is also the most useful thing on the screen when the
// top answer looks wrong to a farmer who knows their own crop.
//
// The data has been computed and stored on every diagnosis all along; nothing
// in the UI read it until now.

class _AlternativesCard extends StatelessWidget {
  final Diagnosis diagnosis;

  const _AlternativesCard({required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alternatives = diagnosis.alternatives;
    if (alternatives.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: context.tr('other_possibilities_title'),
          icon: Icons.alt_route_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          key: const Key('alternatives_card'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('other_possibilities_desc'),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.smPlus),
              for (final alternative in alternatives) ...[
                _AlternativeRow(alternative: alternative),
                if (alternative != alternatives.last)
                  const SizedBox(height: AppSpacing.smPlus),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _AlternativeRow extends StatelessWidget {
  final AlternativePrediction alternative;

  const _AlternativeRow({required this.alternative});

  /// Alternatives always carry a real disease id, so the prettifier should
  /// always succeed; the id itself is a readable last resort rather than a
  /// crash or a blank row.
  String _alternativeName(AlternativePrediction a) =>
      _formatDiseaseName(a.diseaseId) ?? a.diseaseId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (alternative.confidence * 100).toStringAsFixed(0);

    return Semantics(
      label: '${_alternativeName(alternative)}, $percent%',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _alternativeName(alternative),
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                // A bar rather than a bare number: relative size is readable
                // without reading, which matters for the audience this app is
                // built for.
                ClipRRect(
                  borderRadius: AppRadius.sm,
                  child: LinearProgressIndicator(
                    value: alternative.confidence.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.smPlus),
          Text(
            '$percent%',
            style: theme.textTheme.labelMedium,
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
