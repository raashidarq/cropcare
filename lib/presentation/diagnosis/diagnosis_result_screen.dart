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

  /// Opens the camera for another scan.
  ///
  /// Supplied by whoever pushed this screen, because they hold the capture
  /// use cases and this screen does not. Without it the button falls back to
  /// popping home, which is where "Scan again" used to land - one tap short
  /// of what it said it would do.
  final void Function(BuildContext context)? onScanAgain;
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
    this.onScanAgain,
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
          onScanAgain: onScanAgain,
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
      onScanAgain: onScanAgain,
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
  final void Function(BuildContext context)? onScanAgain;
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
    this.onScanAgain,
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
    _speechService = widget.speechService ?? DeviceSpeechRecognitionService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_explanationRequested) return;
    _explanationRequested = true;

    final diseaseId = widget.diagnosis.diseaseId;
    if (diseaseId == null) return;

    final languageCode = LocalizationProvider.of(context)?.languageCode ?? 'en';

    // Two passes. The guidance shipped with the app is a local read - no
    // network, no cost, no waiting, and already translated - so it paints
    // first and the screen is never blank. The AI answer is the better one:
    // short ordered steps written for this crop and this confidence level. It
    // now fetches on its own rather than waiting for a tap, because the
    // earlier reasoning ("it costs mobile data") conflated a megabyte photo
    // upload with a text request and a page of JSON back.
    //
    // If the AI call fails, the local guidance stays on screen. The farmer is
    // never left with less than they started with.
    final cubit = context.read<DiagnosisCubit?>();
    cubit
        ?.loadLocalGuidance(diseaseId: diseaseId, languageCode: languageCode)
        .then((_) {
      if (!mounted) return;
      cubit.autoFetchAiGuidance(
        diagnosisId: widget.diagnosis.id,
        cropId: widget.scan.cropId,
        diseaseId: diseaseId,
        confidence: widget.diagnosis.confidence,
        severity: widget.diagnosis.severity,
        languageCode: languageCode,
      );
    });

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
    final languageCode = LocalizationProvider.of(context)?.languageCode ?? 'en';
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
    final treatmentSummary = state is DiagnosisTreatmentLoaded
        ? state.treatment.summary
        : null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          speechService: _speechService,
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
    final isLowConfidence =
        !isHealthy &&
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
              // SingleChildScrollView, not ListView: the screen is short
              // enough now that lazy building buys nothing, and a ListView
              // silently skips building off-screen children — which makes
              // read-aloud, semantics and widget tests all behave differently
              // depending on scroll position.
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
                    // The photo, the name, and one line about how much to
                    // trust it. This used to be five separate widgets — a
                    // state chip, a severity chip, a confidence meter, a
                    // caveat banner and a standing AI disclaimer — which is
                    // four different ways of saying "how sure are we" stacked
                    // above the thing the farmer actually came for.
                    _ResultHeader(
                      scan: widget.scan,
                      diagnosis: widget.diagnosis,
                      isLowConfidence: isLowConfidence,
                    ),

                    if (isHealthy)
                      const _HealthyNote()
                    else if (widget.diagnosis.diseaseId != null) ...[
                      // What to do, as steps. The whole screen exists for this.
                      _GuidanceSection(
                        ttsService: _ttsService,
                        onFetch: () => _fetchTreatment(context),
                      ),
                      _OtherPossibilities(diagnosis: widget.diagnosis),
                    ],

                    if (widget.getChatHistoryUseCase != null &&
                        widget.sendChatMessageUseCase != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _AskAboutResultButton(onTap: () => _openChat(context)),
                    ],

                    // Renders nothing when no content is stored, which is
                    // currently every disease.
                    if (_explanationFuture != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _ExplanationSection(future: _explanationFuture!),
                    ],
                  ],
                ),
              ),
            ),
            _BottomActions(
              onScanAgain: () {
                final again = widget.onScanAgain;
                if (again == null) {
                  // No capture use cases were threaded in (a direct push, or
                  // a test). Home is the best available destination.
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  return;
                }
                // Leave the result behind before opening the camera, so the
                // back button from the viewfinder does not return to a stale
                // diagnosis of a different leaf.
                Navigator.of(context).pop();
                again(context);
              },
              onConsultExpert: () => _navigateToEscalation(context),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Result hero — the photo, the verdict, and how much to trust it
// =============================================================================

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
      cacheWidth:
          (MediaQuery.sizeOf(context).width *
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

// =============================================================================
// Healthy Confirmation Card
// =============================================================================

// =============================================================================
// Observations Input Card (Optional)
// =============================================================================

// =============================================================================
// Treatment Guidance Section
// =============================================================================

/// Speaks the guidance once, if auto-read is enabled. Guarded by a set of
/// already-spoken treatments so a rebuild does not restart playback.
final Set<String> _autoReadFired = <String>{};

void _maybeAutoRead(
  BuildContext context,
  TreatmentResponse treatment,
  TtsService? tts,
) {
  final AccessibilityCubit cubit;
  try {
    cubit = context.read<AccessibilityCubit>();
  } catch (_) {
    return;
  }
  if (!cubit.state.autoReadDiagnosis) return;

  final signature = '${treatment.interpretationId}|${treatment.summary}';
  if (!_autoReadFired.add(signature)) return;

  if (tts == null) return;

  final lang = LocalizationProvider.of(context)?.languageCode ?? 'en';
  final text =
      '${treatment.summary}. ${context.tr('treatment_what_to_do')}: ${treatment.whatToDo}. ${context.tr('treatment_what_to_avoid')}: ${treatment.whatToAvoid}.';

  WidgetsBinding.instance.addPostFrameCallback((_) {
    tts.speak(
      text: text,
      languageCode: lang,
      speechRate: cubit.state.speechRate,
    );
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
    // Pinned chrome, so it needs to look pinned. Previously this was a bare
    // Column dropped at the bottom of the screen: no padding, so the buttons
    // sat flush against the screen edges; no background or border, so content
    // scrolled up to touch them with nothing marking where the page ended;
    // and no bottom inset, so on a gesture-navigation phone the lower button
    // sat under the home indicator.
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
                width: double.infinity,
                height: AppSpacing.minTouchTarget,
                child: ElevatedButton.icon(
                  key: const Key('diagnosis_scan_again_button'),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: Text(context.tr('scan_again')),
                  onPressed: onScanAgain,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // A text button, not a second full-height outlined one. Two
              // stacked 48dp buttons plus padding took about a fifth of a
              // small phone's screen permanently, competing with the result
              // itself. This still meets the 48dp touch target through the
              // button's own minimum size.
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  key: const Key('diagnosis_expert_button'),
                  icon: const Icon(Icons.support_agent_rounded, size: 20),
                  label: Text(context.tr('ask_an_expert')),
                  onPressed: onConsultExpert,
                ),
              ),
            ],
          ),
        ),
      ),
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
                confusions: explanation.confusions
                    .where((c) => !c.isEmpty)
                    .toList(),
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

// =============================================================================
// Ask about this result
// =============================================================================

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

// =============================================================================
// Result header — the photo, the name, and one line about trusting it
// =============================================================================

/// Everything a farmer needs to know about *what this is*, in one block.
///
/// This replaced five stacked widgets: a "likely match" chip, a severity chip,
/// a confidence meter, a low-confidence banner and a standing AI disclaimer.
/// That was four different renderings of the same question — how sure are we —
/// piled above the thing the farmer actually opened the app for. One line of
/// plain words carries it, and the amber note appears only when there is
/// genuinely a reason to hesitate.
class _ResultHeader extends StatelessWidget {
  final Scan scan;
  final Diagnosis diagnosis;
  final bool isLowConfidence;

  const _ResultHeader({
    required this.scan,
    required this.diagnosis,
    required this.isLowConfidence,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHealthy = diagnosis.isHealthy;
    final visual = CropVisuals.forCrop(scan.cropId);
    final percent = (diagnosis.confidence * 100).toStringAsFixed(0);

    final title = isHealthy
        ? context.tr('result_healthy_title')
        : (_formatDiseaseName(diagnosis.diseaseId) ??
              context.tr('unknown_disease'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Hero(
          tag: 'scan-image-${scan.id}',
          child: ClipRRect(
            borderRadius: AppRadius.lg,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ScanImage(path: scan.imageLocalPath),
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
                            _cropLabel(context),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                            ),
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
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: isHealthy ? AppColors.success : AppColors.onSurface,
          ),
        ),
        if (!isHealthy) ...[
          const SizedBox(height: AppSpacing.xs),
          // One trust line, in words first and a number second. The number
          // alone means little to most people; "not certain" does.
          Text(
            '${_trustWord(context)} · '
            '${context.tr('confidence_percent').replaceFirst('{percent}', percent)}'
            '${diagnosis.severity != null ? ' · ${context.tr('severity_label')}: ${diagnosis.severity}' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isLowConfidence
                  ? AppColors.onWarningContainer
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ],
        if (isLowConfidence) ...[
          const SizedBox(height: AppSpacing.smPlus),
          AppBanner.warning(
            title: context.tr('low_confidence_title'),
            message: context.tr('low_confidence_msg'),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  String _trustWord(BuildContext context) {
    switch (diagnosis.resultState) {
      case DiagnosisResultState.confident:
        return context.tr('badge_confident');
      case DiagnosisResultState.lowConfidence:
        return context.tr('badge_low_confidence');
      case DiagnosisResultState.unsupported:
        return context.tr('badge_unsupported');
      case DiagnosisResultState.analysisFailed:
        return context.tr('badge_failed');
    }
  }

  String _cropLabel(BuildContext context) {
    final id = scan.cropId;
    if (id.isEmpty || id == 'unknown') return context.tr('unknown_disease');
    return _formatDiseaseName(id) ?? id;
  }
}

// =============================================================================
// Healthy
// =============================================================================

class _HealthyNote extends StatelessWidget {
  const _HealthyNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.success),
        const SizedBox(width: AppSpacing.smPlus),
        Expanded(
          child: Text(
            context.tr('healthy_crop_msg'),
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Guidance — the reason the screen exists
// =============================================================================

/// "Do this now" and "Avoid", as short numbered steps.
///
/// Previously this was a raised Card containing a title row, a source badge, a
/// read-aloud button and three more coloured sub-blocks, each with its own
/// icon, background and padding — a card inside a card inside a card, holding
/// three paragraphs of prose. A farmer had to read all of it to find the one
/// thing to do first.
///
/// Now the steps are the content: flat, numbered, ordered by urgency by the
/// backend. Everything else — where the advice came from, read-aloud, the
/// option to fetch fresher advice — is secondary and rendered as such.
class _GuidanceSection extends StatelessWidget {
  final VoidCallback onFetch;
  final TtsService? ttsService;

  const _GuidanceSection({required this.onFetch, this.ttsService});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<DiagnosisCubit?>();
    if (cubit == null) return const SizedBox.shrink();
    final state = cubit.state;

    if (state is DiagnosisTreatmentLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
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
      _maybeAutoRead(context, state.treatment, ttsService);
      return _GuidanceBody(
        treatment: state.treatment,
        ttsService: ttsService,
        onFetch: onFetch,
        isAi: state.isAi,
        isRefreshing: state.isRefreshing,
        refreshFailed: state.refreshFailed,
      );
    }

    // Nothing on the device for this disease AND the automatic attempt has
    // not produced anything, so asking is the only route left. This one keeps
    // "Get AI recommendation": for this farmer it really is a first request.
    return SizedBox(
      height: AppSpacing.minTouchTarget,
      child: ElevatedButton.icon(
        key: const Key('get_treatment_guidance_button'),
        icon: const Icon(Icons.medical_information_outlined),
        label: Text(context.tr('get_treatment_btn')),
        onPressed: onFetch,
      ),
    );
  }
}

class _GuidanceBody extends StatelessWidget {
  final TreatmentResponse treatment;
  final TtsService? ttsService;
  final VoidCallback onFetch;
  final bool isAi;
  final bool isRefreshing;
  final bool refreshFailed;

  const _GuidanceBody({
    required this.treatment,
    required this.onFetch,
    this.ttsService,
    this.isAi = false,
    this.isRefreshing = false,
    this.refreshFailed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doSteps = treatment.effectiveDoSteps;
    final avoidSteps = treatment.effectiveAvoidSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (treatment.summary.isNotEmpty) ...[
          Text(treatment.summary, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
        ],

        if (doSteps.isNotEmpty) ...[
          _SectionLabel(
            label: context.tr('do_this_now'),
            // Read-aloud sits here rather than as a full-width button of its
            // own: it is the path through this screen for someone who does
            // not read comfortably, so it belongs beside the text it reads,
            // not floating above it.
            trailing: ttsService == null
                ? null
                : _ReadAloudButton(
                    ttsService: ttsService!,
                    treatment: treatment,
                  ),
          ),
          const SizedBox(height: AppSpacing.smPlus),
          for (var i = 0; i < doSteps.length; i++) ...[
            _Step(number: i + 1, text: doSteps[i]),
            if (i != doSteps.length - 1)
              const SizedBox(height: AppSpacing.smPlus),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],

        if (avoidSteps.isNotEmpty) ...[
          _SectionLabel(label: context.tr('treatment_what_to_avoid')),
          const SizedBox(height: AppSpacing.smPlus),
          for (final step in avoidSteps) ...[
            _AvoidItem(text: step),
            if (step != avoidSteps.last) const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],

        if (treatment.recheckAfterDays != null) ...[
          Row(
            children: [
              const Icon(
                Icons.event_repeat_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context
                      .tr('recheck_after')
                      .replaceFirst('{days}', '${treatment.recheckAfterDays}'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Where this came from, and how to get better advice. A footnote,
        // not a badge competing with the steps for attention.
        Row(
          key: const Key('treatment_source_badge'),
          children: [
            if (isRefreshing)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                isAi ? Icons.auto_awesome : Icons.offline_pin_outlined,
                size: 14,
                color: AppColors.onSurfaceVariant,
              ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                isRefreshing
                    // Says what is happening AND that the steps above are
                    // real and usable meanwhile.
                    ? context.tr('treatment_improving')
                    : isAi
                        ? context.tr('treatment_source_ai')
                        : context.tr('treatment_source_offline'),
                style: theme.textTheme.labelSmall,
              ),
            ),
            // Offered only when there is something to gain: the guidance is
            // not AI-written and nothing is in flight. "Retry AI" rather than
            // "Get AI recommendation" - the fetch already happened on its own,
            // so this is a second attempt, not a first request.
            if (!isAi && !isRefreshing)
              TextButton(
                key: const Key('refresh_treatment_guidance_button'),
                onPressed: onFetch,
                child: Text(context.tr('retry_ai_btn')),
              ),
          ],
        ),

        // Only after a failure, and deliberately quiet: the farmer still has
        // working guidance above, so this is a footnote, not an alarm.
        if (refreshFailed) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('treatment_ai_failed_note'),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.onWarningContainer,
            ),
          ),
        ],
      ],
    );
  }
}

/// A small all-caps-free heading. Sentence case, because uppercase does not
/// exist in Sinhala or Tamil and made the three languages look inconsistent.
class _SectionLabel extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const _SectionLabel({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
        ?trailing,
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String text;

  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A number, not a bullet: these are ordered by urgency, and the order
        // is information.
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.smPlus),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}

class _AvoidItem extends StatelessWidget {
  final String text;

  const _AvoidItem({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: Icon(Icons.close_rounded, size: 18, color: AppColors.error),
        ),
        const SizedBox(width: AppSpacing.smPlus),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _ReadAloudButton extends StatelessWidget {
  final TtsService ttsService;
  final TreatmentResponse treatment;

  const _ReadAloudButton({required this.ttsService, required this.treatment});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ttsService.isPlaying,
      builder: (context, isPlaying, _) {
        return IconButton(
          key: const Key('treatment_tts_button'),
          onPressed: () {
            if (isPlaying) {
              ttsService.stop();
              return;
            }
            final lang = LocalizationProvider.of(context)?.languageCode ?? 'en';
            // Reads the prose forms, not the step list: flowing sentences
            // sound like speech, a numbered list read aloud does not.
            final speechText =
                '${treatment.summary}. '
                '${context.tr('treatment_what_to_do')}: ${treatment.whatToDo} '
                '${context.tr('treatment_what_to_avoid')}: ${treatment.whatToAvoid}';
            ttsService.speak(
              text: speechText,
              languageCode: lang,
              speechRate: _speechRateOf(context),
            );
          },
          tooltip: isPlaying
              ? context.tr('stop_reading')
              : context.tr('read_aloud'),
          icon: Icon(
            isPlaying ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
            color: isPlaying ? AppColors.error : AppColors.primary,
          ),
        );
      },
    );
  }
}

// =============================================================================
// Other possibilities
// =============================================================================

/// The runner-up predictions, framed as a question rather than a data readout.
///
/// This was a section header plus a bordered card plus a progress bar and a
/// percentage per row — a chart, essentially, for information that answers one
/// simple question: "the app says X, but I do not think it is X, so what else
/// could it be?" It now reads as that question, and the percentages are
/// dropped: a farmer cannot act on "21%", and the ordering already carries
/// everything the number was telling them.
class _OtherPossibilities extends StatelessWidget {
  final Diagnosis diagnosis;

  const _OtherPossibilities({required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Belt and braces alongside the repository's repair: a bare class index
    // is meaningless to a farmer, so anything that still looks like one is
    // dropped rather than rendered. Better to show fewer possibilities than
    // to show "12".
    final alternatives = diagnosis.alternatives
        .where((a) =>
            a.diseaseId.isNotEmpty && int.tryParse(a.diseaseId) == null)
        .toList();
    if (alternatives.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        key: const Key('alternatives_card'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('other_possibilities_title'),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('other_possibilities_desc'),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.smPlus),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final alternative in alternatives)
                _PossibilityChip(
                  label:
                      _formatDiseaseName(alternative.diseaseId) ??
                      alternative.diseaseId,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PossibilityChip extends StatelessWidget {
  final String label;

  const _PossibilityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.smPlus,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.md,
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurface),
      ),
    );
  }
}

// =============================================================================
// Ask about this result
// =============================================================================

class _AskAboutResultButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AskAboutResultButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.minTouchTarget,
      child: OutlinedButton.icon(
        key: const Key('ask_about_result_card'),
        icon: const Icon(Icons.forum_outlined),
        label: Text(context.tr('chat_with_result_title')),
        onPressed: onTap,
      ),
    );
  }
}
