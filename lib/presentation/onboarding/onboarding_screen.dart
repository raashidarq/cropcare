// lib/presentation/onboarding/onboarding_screen.dart
//
// First-run introduction.
//
// Two things changed structurally:
//
//  1. LANGUAGE NOW COMES FIRST. The old flow was Splash → Onboarding →
//     Language, so every word of the introduction was shown in English before
//     the user had any way to say they read Sinhala or Tamil. For the audience
//     this app is for, that made the entire introduction unreadable. Language
//     selection now runs ahead of these slides, and this screen is reached
//     already translated.
//  2. IT ENDS WITH A CHOICE. The last step asks whether to create an account
//     or continue as a guest, instead of dropping the user on the home screen
//     with no idea that an account exists. The guest path is a first-class
//     button, not fine print — most farmers will take it, and the note under
//     it says nothing is lost by doing so.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/onboarding/app_state_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'localization/localization_provider.dart';

class OnboardingScreen extends StatefulWidget {
  /// The language chosen on the previous screen. Completing onboarding needs
  /// it, and this screen - not its caller - is the one that's still mounted
  /// when the user actually makes that choice, several slides later.
  final String languageCode;

  /// Preview mode: shown from Settings to review the flow. Hides the final
  /// account step (there is nothing to decide) and just pops when done.
  final bool isPreview;

  const OnboardingScreen({
    super.key,
    this.languageCode = 'en',
    this.isPreview = false,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _index = 0;

  static const List<_Slide> _slides = [
    _Slide(
      icon: Icons.eco_rounded,
      titleKey: 'onboarding_welcome_title',
      bodyKey: 'onboarding_welcome_body',
      tint: AppColors.primary,
    ),
    _Slide(
      icon: Icons.photo_camera_rounded,
      titleKey: 'onboarding_scan_title',
      bodyKey: 'onboarding_scan_body',
      tint: AppColors.info,
    ),
    _Slide(
      icon: Icons.cloud_off_rounded,
      titleKey: 'onboarding_offline_title',
      bodyKey: 'onboarding_offline_body',
      tint: AppColors.treatmentSourceOffline,
    ),
    _Slide(
      icon: Icons.support_agent_rounded,
      titleKey: 'onboarding_expert_title',
      bodyKey: 'onboarding_expert_body',
      tint: AppColors.treatmentSourceAi,
    ),
  ];

  int get _stepCount => widget.isPreview ? _slides.length : _slides.length + 1;
  bool get _isFinalStep => _index == _stepCount - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_isFinalStep) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() {
    if (widget.isPreview) {
      Navigator.of(context).pop();
      return;
    }
    _completeAndEnter(openAuth: false);
  }

  /// Completes onboarding and enters the app. [openAuth] routes straight to
  /// account creation; otherwise the user lands on Home as a guest.
  ///
  /// Does NOT navigate itself. `AppStateCubit.completeOnboarding` emits
  /// `AppStateOnboardingComplete`, and app.dart's own root `BlocBuilder`
  /// reacts to that by swapping `MaterialApp.home` to the real, fully-wired
  /// `HomeScreen` (the one built with `authCubit`, `syncCubit` and every
  /// real use case - see app.dart). This screen was only ever reached via
  /// `pushReplacement`, so it is still the Navigator's one and only route;
  /// that reactive swap is enough on its own to put HomeScreen on screen.
  ///
  /// This used to also push its own, separately-constructed
  /// `HomeScreen(openAccountOnLaunch: openAuth)` here. That copy had no
  /// `authCubit`/`syncCubit` (or any of the use cases) in its subtree, so
  /// screens that read them via `context.read` — e.g. Settings > Offline &
  /// Storage reading `SyncCubit` — threw `ProviderNotFoundException` the
  /// moment they were opened. In release builds that renders as a blank
  /// grey screen with no visible error (Flutter's release-mode default
  /// `ErrorWidget`); in debug it would have shown the usual red error
  /// screen. Confirmed live via `adb logcat` against a real release build
  /// (TD-032): "Provider&lt;SyncCubit&gt; not found for
  /// BlocConsumer&lt;SyncCubit, SyncState&gt;". `openAuth` now travels
  /// through `AppStateCubit` instead,
  /// as a one-shot, non-persisted flag on the emitted state, so the real
  /// HomeScreen can act on it with all of its dependencies intact.
  Future<void> _completeAndEnter({required bool openAuth}) async {
    await context.read<AppStateCubit>().completeOnboarding(
      widget.languageCode,
      openAccountOnLaunch: openAuth,
    );
  }

  void _skip() {
    if (widget.isPreview) {
      Navigator.of(context).pop();
      return;
    }
    // Skipping jumps to the account step rather than out of the flow — the
    // choice still has to be made, it just stops explaining first.
    _pageController.animateToPage(
      _stepCount - 1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showAccountStep = !widget.isPreview;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              index: _index,
              stepCount: _stepCount,
              onSkip: _isFinalStep ? null : _skip,
              skipLabel: widget.isPreview
                  ? context.tr('close')
                  : context.tr('skip'),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _stepCount,
                itemBuilder: (context, i) {
                  if (showAccountStep && i == _slides.length) {
                    return _AccountStep(
                      onCreateAccount: () => _completeAndEnter(openAuth: true),
                      onContinueAsGuest: () => _completeAndEnter(openAuth: false),
                    );
                  }
                  return _SlideView(slide: _slides[i]);
                },
              ),
            ),
            // The account step carries its own buttons, so the shared Next
            // control would be a second, competing primary action.
            if (!(showAccountStep && _isFinalStep))
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    key: const Key('onboarding_next_button'),
                    onPressed: _next,
                    child: Text(
                      _isFinalStep
                          ? context.tr('onboarding_get_started')
                          : context.tr('onboarding_next'),
                    ),
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
// Pieces
// =============================================================================

class _Slide {
  final IconData icon;
  final String titleKey;
  final String bodyKey;
  final Color tint;

  const _Slide({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
    required this.tint,
  });
}

class _TopBar extends StatelessWidget {
  final int index;
  final int stepCount;
  final VoidCallback? onSkip;
  final String skipLabel;

  const _TopBar({
    required this.index,
    required this.stepCount,
    required this.onSkip,
    required this.skipLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.smPlus,
        AppSpacing.smPlus,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          // A segmented bar rather than dots: it shows how much is left, not
          // just where you are, which is what makes people willing to
          // continue.
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < stepCount; i++) ...[
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= index
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                        borderRadius: AppRadius.full,
                      ),
                    ),
                  ),
                  if (i < stepCount - 1) const SizedBox(width: AppSpacing.xs),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.smPlus),
          SizedBox(
            height: AppSpacing.minTouchTarget,
            child: TextButton(
              key: const Key('onboarding_skip_button'),
              onPressed: onSkip,
              child: Text(skipLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;

  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Layered discs instead of a flat icon: gives the illustration area
          // some depth without needing artwork, which this project has no
          // pipeline for.
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: slide.tint.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: slide.tint.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(slide.icon, size: 72, color: slide.tint),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            context.tr(slide.titleKey),
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.smPlus),
          Text(
            context.tr(slide.bodyKey),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The closing step: account or guest.
class _AccountStep extends StatelessWidget {
  final VoidCallback? onCreateAccount;
  final VoidCallback? onContinueAsGuest;

  const _AccountStep({this.onCreateAccount, this.onContinueAsGuest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('onboarding_get_started'),
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.smPlus),
          Text(
            context.tr('onboarding_guest_note'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              key: const Key('onboarding_create_account_button'),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(context.tr('onboarding_create_account')),
              onPressed: onCreateAccount,
            ),
          ),
          const SizedBox(height: AppSpacing.smPlus),
          SizedBox(
            height: 52,
            // Guest is an equal-weight option, not a dismissive link: it is
            // the path most users will and should take on first run.
            child: OutlinedButton(
              key: const Key('onboarding_continue_guest_button'),
              onPressed: onContinueAsGuest,
              child: Text(context.tr('onboarding_continue_guest')),
            ),
          ),
        ],
      ),
    );
  }
}
