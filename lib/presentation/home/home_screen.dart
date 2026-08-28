// lib/presentation/home/home_screen.dart
//
// App shell: a bottom navigation bar over three destinations.
//
// Why a bottom nav at all: the previous home screen carried the scan action,
// the entire scan history with its filters, and reached Settings and Profile
// only through small unlabelled icons in the AppBar. Icon-only affordances in
// a top corner are the least discoverable control on a phone, which is a poor
// fit for an audience that may not read fluently. Labelled destinations along
// the bottom are permanently visible, thumb-reachable, and carry a word as
// well as a glyph.
//
// Each destination supplies its own Scaffold and AppBar; this shell provides
// only the body and the navigation bar.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/auth/auth_cubit.dart';
import '../../application/history/history_cubit.dart';
import '../../application/sync/sync_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/crop.dart';
import '../../domain/entities/local_user.dart';
import '../../domain/entities/scan.dart';
import '../../domain/entities/scan_history_item.dart';
import '../../domain/repositories/crop_repository.dart';
import '../../domain/repositories/scan_repository.dart';
import '../../domain/usecases/crop/get_supported_crops_use_case.dart';
import '../../domain/usecases/diagnosis/get_disease_explanation_use_case.dart';
import '../../domain/usecases/chat/delete_chat_message_use_case.dart';
import '../../domain/usecases/chat/get_chat_history_use_case.dart';
import '../../domain/usecases/chat/send_chat_message_use_case.dart';
import '../../domain/usecases/diagnosis/get_cached_ai_treatment_use_case.dart';
import '../../domain/usecases/diagnosis/get_local_treatment_guidance_use_case.dart';
import '../../domain/usecases/diagnosis/resolve_treatment_use_case.dart';
import '../../domain/usecases/diagnosis/run_diagnosis_use_case.dart';
import '../../domain/usecases/diagnosis/validate_image_use_case.dart';
import '../../domain/usecases/escalation/create_escalation_use_case.dart';
import '../../domain/usecases/feedback/submit_feedback_use_case.dart';
import '../../domain/usecases/history/export_scan_history_use_case.dart';
import '../../domain/usecases/history/delete_scan_use_case.dart';
import '../../domain/usecases/history/get_scan_history_use_case.dart';
import '../auth/auth_screen.dart';
import '../diagnosis/diagnosis_result_screen.dart';
import '../../data/local/preferences/tutorial_preferences.dart';
import '../shared/widgets/tutorial_overlay.dart';
import '../onboarding/localization/localization_provider.dart';
import '../scan/capture_screen.dart';
import '../scan/scan_result_screen.dart';
import '../settings/profile_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/history_view.dart';
import 'widgets/home_dashboard.dart';

class _FallbackCropRepository implements CropRepository {
  @override
  Future<List<Crop>> getSupportedCrops() async => [
        const Crop(
          id: 'tomato',
          nameEn: 'Tomato',
          nameSi: 'තක්කාලි',
          nameTa: 'தக்காளி',
        ),
        const Crop(
          id: 'chili',
          nameEn: 'Chili',
          nameSi: 'මිරිස්',
          nameTa: 'மிளகாய்',
        ),
      ];
}

class _FallbackScanRepository implements ScanRepository {
  @override
  Future<Scan> createScan({
    required String cropId,
    required String imageLocalPath,
    required String userId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Scan?> getScanById(String id) async => null;

  @override
  Future<void> updateScanStatus(String scanId, ScanStatus status) async {}

  @override
  Future<void> updateScanCrop(String scanId, String cropId) async {}

  @override
  Future<void> rejectInvalidScan({
    required String scanId,
    required String rejectionReason,
  }) async {}

  @override
  Future<int> purgeFailedScans() async => 0;

  @override
  Future<List<ScanHistoryItem>> getScanHistory() async => [];
  @override
  Future<void> deleteScan(String scanId) async {}


  @override
  Future<void> deleteAllLocalScans() async {}
}

class HomeScreen extends StatefulWidget {
  final LocalUser? user;
  final AuthCubit? authCubit;
  final SyncCubit? syncCubit;
  final GetSupportedCropsUseCase? getSupportedCropsUseCase;
  final ValidateImageUseCase? validateImageUseCase;
  final RunDiagnosisUseCase? runDiagnosisUseCase;
  final ResolveTreatmentUseCase? resolveTreatmentUseCase;
  final GetLocalTreatmentGuidanceUseCase? getLocalTreatmentGuidanceUseCase;
  final GetCachedAiTreatmentUseCase? getCachedAiTreatmentUseCase;
  final GetChatHistoryUseCase? getChatHistoryUseCase;
  final SendChatMessageUseCase? sendChatMessageUseCase;
  final DeleteChatMessageUseCase? deleteChatMessageUseCase;
  final GetDiseaseExplanationUseCase? getDiseaseExplanationUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;
  final GetScanHistoryUseCase? getScanHistoryUseCase;
  final DeleteScanUseCase? deleteScanUseCase;
  final ExportScanHistoryUseCase? exportScanHistoryUseCase;
  final SubmitFeedbackUseCase? submitFeedbackUseCase;

  /// Opens the account screen immediately after launch. Set when the user
  /// chose "Create an account" at the end of onboarding, so that choice is
  /// not silently dropped on the way to Home.
  final bool openAccountOnLaunch;

  const HomeScreen({
    super.key,
    this.user,
    this.authCubit,
    this.syncCubit,
    this.getSupportedCropsUseCase,
    this.validateImageUseCase,
    this.runDiagnosisUseCase,
    this.resolveTreatmentUseCase,
    this.getLocalTreatmentGuidanceUseCase,
    this.getCachedAiTreatmentUseCase,
    this.getChatHistoryUseCase,
    this.sendChatMessageUseCase,
    this.deleteChatMessageUseCase,
    this.getDiseaseExplanationUseCase,
    this.createEscalationUseCase,
    this.getScanHistoryUseCase,
    this.deleteScanUseCase,
    this.exportScanHistoryUseCase,
    this.submitFeedbackUseCase,
    this.openAccountOnLaunch = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late LocalUser _user;
  late final GetSupportedCropsUseCase _getSupportedCropsUseCase;
  late final GetScanHistoryUseCase _getScanHistoryUseCase;

  @override
  void initState() {
    super.initState();
    _user = widget.user ??
        widget.authCubit?.currentUser ??
        LocalUser(
          id: 'guest-default',
          isGuest: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    _getSupportedCropsUseCase = widget.getSupportedCropsUseCase ??
        GetSupportedCropsUseCase(_FallbackCropRepository());
    _getScanHistoryUseCase = widget.getScanHistoryUseCase ??
        GetScanHistoryUseCase(_FallbackScanRepository());
  }

  void _onUserUpdated(LocalUser updatedUser) {
    setState(() => _user = updatedUser);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HistoryCubit>(
      create: (_) => HistoryCubit(
        getScanHistoryUseCase: _getScanHistoryUseCase,
        deleteScanUseCase: widget.deleteScanUseCase,
      )..loadHistory(),
      child: _AppShell(
        user: _user,
        authCubit: widget.authCubit,
        syncCubit: widget.syncCubit,
        onUserUpdated: _onUserUpdated,
        getSupportedCropsUseCase: _getSupportedCropsUseCase,
        validateImageUseCase: widget.validateImageUseCase,
        runDiagnosisUseCase: widget.runDiagnosisUseCase,
        resolveTreatmentUseCase: widget.resolveTreatmentUseCase,
        getLocalTreatmentGuidanceUseCase: widget.getLocalTreatmentGuidanceUseCase,
        getCachedAiTreatmentUseCase: widget.getCachedAiTreatmentUseCase,
        getChatHistoryUseCase: widget.getChatHistoryUseCase,
        sendChatMessageUseCase: widget.sendChatMessageUseCase,
        deleteChatMessageUseCase: widget.deleteChatMessageUseCase,
        getDiseaseExplanationUseCase: widget.getDiseaseExplanationUseCase,
        createEscalationUseCase: widget.createEscalationUseCase,
        exportScanHistoryUseCase: widget.exportScanHistoryUseCase,
        submitFeedbackUseCase: widget.submitFeedbackUseCase,
        openAccountOnLaunch: widget.openAccountOnLaunch,
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  final LocalUser user;
  final AuthCubit? authCubit;
  final SyncCubit? syncCubit;
  final ValueChanged<LocalUser> onUserUpdated;
  final GetSupportedCropsUseCase getSupportedCropsUseCase;
  final ValidateImageUseCase? validateImageUseCase;
  final RunDiagnosisUseCase? runDiagnosisUseCase;
  final ResolveTreatmentUseCase? resolveTreatmentUseCase;
  final GetLocalTreatmentGuidanceUseCase? getLocalTreatmentGuidanceUseCase;
  final GetCachedAiTreatmentUseCase? getCachedAiTreatmentUseCase;
  final GetChatHistoryUseCase? getChatHistoryUseCase;
  final SendChatMessageUseCase? sendChatMessageUseCase;
  final DeleteChatMessageUseCase? deleteChatMessageUseCase;
  final GetDiseaseExplanationUseCase? getDiseaseExplanationUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;
  final ExportScanHistoryUseCase? exportScanHistoryUseCase;
  final SubmitFeedbackUseCase? submitFeedbackUseCase;
  final bool openAccountOnLaunch;

  const _AppShell({
    required this.user,
    this.authCubit,
    this.syncCubit,
    required this.onUserUpdated,
    required this.getSupportedCropsUseCase,
    this.validateImageUseCase,
    this.runDiagnosisUseCase,
    this.resolveTreatmentUseCase,
    this.getLocalTreatmentGuidanceUseCase,
    this.getCachedAiTreatmentUseCase,
    this.getChatHistoryUseCase,
    this.sendChatMessageUseCase,
    this.deleteChatMessageUseCase,
    this.getDiseaseExplanationUseCase,
    this.createEscalationUseCase,
    this.exportScanHistoryUseCase,
    this.submitFeedbackUseCase,
    this.openAccountOnLaunch = false,
  });

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _index = 0;

  /// Tabs the user has actually opened. IndexedStack builds every child
  /// eagerly, which would construct the entire Settings tree — and resolve
  /// its dependencies — during the first frame of the app, on a device where
  /// that cost is real. Tabs are therefore built on first visit and kept
  /// alive afterwards, which is what IndexedStack is actually wanted for.
  final Set<int> _visited = {0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTutorial());

    if (widget.openAccountOnLaunch) {
      // Deferred to the first frame: the shell has to exist before anything
      // can be pushed on top of it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleAccountAction();
      });
    }
  }

  /// Straight to the viewfinder. There is no longer an intermediate
  /// "camera or gallery?" screen — gallery lives inside the camera UI, so
  /// the common case costs one tap instead of two.
  Future<void> _startScan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaptureScreen(
          user: widget.user,
          validateImageUseCase: widget.validateImageUseCase,
          runDiagnosisUseCase: widget.runDiagnosisUseCase,
          resolveTreatmentUseCase: widget.resolveTreatmentUseCase,
          getLocalTreatmentGuidanceUseCase: widget.getLocalTreatmentGuidanceUseCase,
          getCachedAiTreatmentUseCase: widget.getCachedAiTreatmentUseCase,
          getChatHistoryUseCase: widget.getChatHistoryUseCase,
          sendChatMessageUseCase: widget.sendChatMessageUseCase,
          deleteChatMessageUseCase: widget.deleteChatMessageUseCase,
        getDiseaseExplanationUseCase: widget.getDiseaseExplanationUseCase,
          createEscalationUseCase: widget.createEscalationUseCase,
        ),
      ),
    );
    if (mounted) context.read<HistoryCubit>().loadHistory();
  }

  void _openScan(ScanHistoryItem item) {
    final diagnosis = item.diagnosis;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => diagnosis == null
            ? ScanResultScreen(scan: item.scan)
            : DiagnosisResultScreen(
                scan: item.scan,
                diagnosis: diagnosis,
                onScanAgain: (_) => _startScan(),
                resolveTreatmentUseCase: widget.resolveTreatmentUseCase,
                getLocalTreatmentGuidanceUseCase: widget.getLocalTreatmentGuidanceUseCase,
                getCachedAiTreatmentUseCase: widget.getCachedAiTreatmentUseCase,
                getChatHistoryUseCase: widget.getChatHistoryUseCase,
                sendChatMessageUseCase: widget.sendChatMessageUseCase,
                deleteChatMessageUseCase: widget.deleteChatMessageUseCase,
        getDiseaseExplanationUseCase: widget.getDiseaseExplanationUseCase,
                createEscalationUseCase: widget.createEscalationUseCase,
              ),
      ),
    );
  }

  Future<void> _handleAccountAction() async {
    final authCubit = widget.authCubit;
    if (authCubit == null) return;
    final currentUser = authCubit.currentUser;

    final updated = await Navigator.push<LocalUser>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: authCubit,
          child: currentUser.isGuest
              ? AuthScreen(currentUser: currentUser)
              : ProfileScreen(user: currentUser, authCubit: authCubit),
        ),
      ),
    );
    if (updated != null) widget.onUserUpdated(updated);
  }

  /// Builds [tab] only once its index has been visited; an unvisited tab
  /// occupies its slot with nothing.
  Widget _lazy(int index, Widget Function() tab) {
    if (!_visited.contains(index)) return const SizedBox.shrink();
    return tab();
  }

  void _select(int index) {
    setState(() {
      _index = index;
      _visited.add(index);
    });
  }

  // Targets for the walkthrough. They live here rather than on the widgets so
  // the tutorial can point at controls it does not own.
  final GlobalKey _scanButtonKey = GlobalKey();
  final GlobalKey _navKey = GlobalKey();

  final TutorialPreferences _tutorialPrefs = TutorialPreferences();
  bool _tutorialChecked = false;

  /// Runs once, after the first frame, so the targets have been laid out and
  /// have rects to point at.
  Future<void> _maybeShowTutorial() async {
    if (_tutorialChecked) return;
    _tutorialChecked = true;
    if (await _tutorialPrefs.hasSeenHomeTutorial()) return;
    if (!mounted) return;
    await _tutorialPrefs.setHomeTutorialSeen(true);
    if (!mounted) return;
    await _runTutorial();
  }

  Future<void> _runTutorial() async {
    // Home first: the walkthrough points at the real screen, so it has to be
    // the one on display.
    if (_index != 0) {
      _select(0);
      // And it has to have been laid out. showTutorial measures the target
      // widgets' rects, and immediately after setState the Home tab has not
      // rendered yet - the spotlight would land on whatever geometry the
      // previous tab left behind, or on nothing at all.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    await showTutorial(context, [
      TutorialStep(
        targetKey: _scanButtonKey,
        titleKey: 'tutorial_scan_title',
        bodyKey: 'tutorial_scan_body',
      ),
      TutorialStep(
        targetKey: _navKey,
        titleKey: 'tutorial_nav_title',
        bodyKey: 'tutorial_nav_body',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home_rounded),
        label: context.tr('nav_home'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.history_outlined),
        selectedIcon: const Icon(Icons.history_rounded),
        label: context.tr('nav_history'),
      ),
      // Labelled for what the tab actually opens. It previously read
      // "Account" but built SettingsScreen, whose AppBar says "Settings" —
      // three of its four sections are app settings, and changing language
      // is the single most-wanted item in it for a trilingual audience.
      // Identity still leads the screen, as a profile header.
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings_rounded),
        label: context.tr('settings_title'),
      ),
    ];

    return Scaffold(
      // IndexedStack keeps each tab's scroll position and state alive when
      // switching, which is what users expect from a bottom nav.
      body: IndexedStack(
        index: _index,
        children: [
          // Order must match `destinations` below.
          _lazy(0, () => _HomeTab(
            user: widget.user,
            scanButtonKey: _scanButtonKey,
            onStartScan: _startScan,
            onSeeAllHistory: () => _select(1),
            onLinkAccount: _handleAccountAction,
            onOpenScan: _openScan,
          )),
          _lazy(1, () => _HistoryTab(
            exportScanHistoryUseCase: widget.exportScanHistoryUseCase,
            onOpenScan: _openScan,
            onStartScan: _startScan,
          )),
          _lazy(2, () => SettingsScreen(
            onReplayTutorial: _runTutorial,
            user: widget.user,
            authCubit: widget.authCubit,
            syncCubit: widget.syncCubit,
            exportScanHistoryUseCase: widget.exportScanHistoryUseCase,
            submitFeedbackUseCase: widget.submitFeedbackUseCase,
          )),
        ],
      ),
      // KeyedSubtree so the nav can carry both keys: the stable test key and
      // the tutorial's spotlight target. Its context resolves to the child's
      // render box, which is what the overlay measures.
      bottomNavigationBar: KeyedSubtree(
        key: _navKey,
        child: NavigationBar(
          key: const Key('app_bottom_nav'),
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: destinations,
        ),
      ),
    );
  }
}

// =============================================================================
// Tabs
// =============================================================================

class _HomeTab extends StatelessWidget {
  final LocalUser user;
  final GlobalKey? scanButtonKey;
  final VoidCallback onStartScan;
  final VoidCallback onSeeAllHistory;
  final VoidCallback onLinkAccount;
  final ValueChanged<ScanHistoryItem> onOpenScan;

  const _HomeTab({
    required this.user,
    this.scanButtonKey,
    required this.onStartScan,
    required this.onSeeAllHistory,
    required this.onLinkAccount,
    required this.onOpenScan,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('app_title')),
        actions: [
          IconButton(
            key: const Key('home_account_icon'),
            icon: Icon(
              user.isGuest
                  ? Icons.account_circle_outlined
                  : Icons.account_circle,
              color: AppColors.onPrimary,
            ),
            tooltip: user.isGuest
                ? context.tr('link_account_btn')
                : context.tr('profile_title'),
            onPressed: onLinkAccount,
          ),
        ],
      ),
      body: HomeDashboard(
        user: user,
        onStartScan: onStartScan,
        onSeeAllHistory: onSeeAllHistory,
        scanButtonKey: scanButtonKey,
        onLinkAccount: onLinkAccount,
        onOpenScan: onOpenScan,
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final ExportScanHistoryUseCase? exportScanHistoryUseCase;
  final ValueChanged<ScanHistoryItem> onOpenScan;
  final VoidCallback onStartScan;

  const _HistoryTab({
    this.exportScanHistoryUseCase,
    required this.onOpenScan,
    required this.onStartScan,
  });

  Future<void> _export(BuildContext context) async {
    final useCase = exportScanHistoryUseCase;
    if (useCase == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final successText = context.tr('export_data_success');
    final emptyText = context.tr('export_data_empty');

    final count = await useCase.execute();
    messenger.showSnackBar(
      SnackBar(content: Text(count > 0 ? successText : emptyText)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('history_title')),
        actions: [
          if (exportScanHistoryUseCase != null)
            IconButton(
              key: const Key('home_export_history_icon'),
              icon: const Icon(Icons.file_download_outlined),
              tooltip: context.tr('export_btn'),
              onPressed: () => _export(context),
            ),
        ],
      ),
      body: HistoryView(
        onOpenScan: onOpenScan,
        onStartScan: onStartScan,
      ),
    );
  }
}
