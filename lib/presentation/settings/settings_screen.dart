// lib/presentation/settings/settings_screen.dart
//
// The Account tab.
//
// Rebuilt on the design system. What changed and why:
//
//  * It was the least-tokenised screen in the app while being one of three
//    bottom-nav destinations — raw `Card`/`ListTile`, inline
//    `TextStyle(fontSize: 12)`, and `colorScheme.*` instead of `AppColors`.
//    It now uses `AppActionTile` / `AppSectionHeader` like everywhere else.
//  * Section headers were `.toUpperCase()`. `AppSectionHeader`'s own
//    documentation explains why that was removed: uppercase is harder to read
//    and does not exist in Sinhala or Tamil, so it made the three languages
//    look inconsistent.
//  * The "Notifications — Coming Soon" row is gone. A row that exists only to
//    tell you it does nothing is a dead end; nothing else in Settings routes
//    nowhere, so it was the odd one out.
//  * The "Replay onboarding" row is gone. It was marked TEMPORARY in source —
//    a reviewer preview hook, never intended to ship.
//  * Export had two hit targets on one row (a trailing button *and* an
//    `onTap`) both running the same export, while also looking like it
//    navigated. It is now one row, one action.
//  * The profile row became a real header: identity, account state, and the
//    thing a guest most needs to know — that their scans are only on this
//    phone.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/auth/auth_cubit.dart';
import '../../application/onboarding/app_state_cubit.dart';
import '../../application/settings/settings_cubit.dart';
import '../../application/settings/settings_state.dart';
import '../../application/sync/sync_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/local_user.dart';
import '../../domain/usecases/feedback/submit_feedback_use_case.dart';
import '../../domain/usecases/history/export_scan_history_use_case.dart';
import '../onboarding/localization/localization_provider.dart';
import '../onboarding/widgets/change_language_dialog.dart';
import '../shared/widgets/app_components.dart';
import 'accessibility_screen.dart';
import 'faq_screen.dart';
import 'feedback_screen.dart';
import 'offline_screen.dart';
import 'profile_screen.dart';
import 'terms_privacy_screen.dart';

class SettingsScreen extends StatelessWidget {
  final LocalUser? user;
  final AuthCubit? authCubit;
  final SyncCubit? syncCubit;
  final ExportScanHistoryUseCase? exportScanHistoryUseCase;
  final SubmitFeedbackUseCase? submitFeedbackUseCase;

  const SettingsScreen({
    super.key,
    this.user,
    this.authCubit,
    this.syncCubit,
    this.exportScanHistoryUseCase,
    this.submitFeedbackUseCase,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsCubit()),
        if (syncCubit != null)
          BlocProvider.value(value: syncCubit!..refreshPendingCount()),
      ],
      child: _SettingsView(
        user: user,
        authCubit: authCubit,
        syncCubit: syncCubit,
        exportScanHistoryUseCase: exportScanHistoryUseCase,
        submitFeedbackUseCase: submitFeedbackUseCase,
      ),
    );
  }
}

class _SettingsView extends StatelessWidget {
  final LocalUser? user;
  final AuthCubit? authCubit;
  final SyncCubit? syncCubit;
  final ExportScanHistoryUseCase? exportScanHistoryUseCase;
  final SubmitFeedbackUseCase? submitFeedbackUseCase;

  const _SettingsView({
    this.user,
    this.authCubit,
    this.syncCubit,
    this.exportScanHistoryUseCase,
    this.submitFeedbackUseCase,
  });

  Future<void> _export(BuildContext context) async {
    final useCase = exportScanHistoryUseCase;
    if (useCase == null) return;
    final count = await useCase.execute();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count > 0
              ? context.tr('export_data_success')
              : context.tr('export_data_empty'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openProfile(BuildContext context, LocalUser currentUser) {
    final cubit = authCubit;
    if (cubit == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: ProfileScreen(user: currentUser, authCubit: cubit),
        ),
      ),
    );
  }

  void _openOffline(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => syncCubit != null
            ? BlocProvider.value(
                value: syncCubit!,
                child: OfflineScreen(user: user, authCubit: authCubit),
              )
            : OfflineScreen(user: user, authCubit: authCubit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLang = context.watch<AppStateCubit>().state.languageCode;

    final currentLangName = switch (currentLang) {
      'si' => context.tr('lang_sinhala'),
      'ta' => context.tr('lang_tamil'),
      _ => context.tr('lang_english'),
    };

    final currentUser = authCubit?.currentUser ?? user;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings_title')),
        elevation: 0,
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: [
              _ProfileHeader(
                user: currentUser,
                onTap: currentUser == null || authCubit == null
                    ? null
                    : () => _openProfile(context, currentUser),
              ),

              // ── Preferences ──────────────────────────────────────────────
              const SizedBox(height: AppSpacing.lg),
              AppSectionHeader(title: context.tr('section_preferences')),
              const SizedBox(height: AppSpacing.sm),
              AppActionTile(
                key: const Key('settings_language_row'),
                icon: Icons.language_rounded,
                title: context.tr('section_language'),
                subtitle: currentLangName,
                onTap: () => ChangeLanguageDialog.show(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppActionTile(
                key: const Key('settings_accessibility_row'),
                icon: Icons.accessibility_new_rounded,
                title: context.tr('section_accessibility'),
                subtitle: context.tr('accessibility_subtitle'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AccessibilityScreen(),
                  ),
                ),
              ),

              // ── Data & storage ───────────────────────────────────────────
              const SizedBox(height: AppSpacing.lg),
              AppSectionHeader(title: context.tr('section_data_storage')),
              const SizedBox(height: AppSpacing.sm),
              AppActionTile(
                key: const Key('settings_offline_data_row'),
                icon: Icons.cloud_sync_outlined,
                title: context.tr('section_offline'),
                subtitle: context.tr('offline_subtitle'),
                onTap: () => _openOffline(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppActionTile(
                key: const Key('settings_export_data_row'),
                icon: Icons.file_download_outlined,
                title: context.tr('export_data_title'),
                subtitle: context.tr('export_data_desc'),
                // One row, one action. The trailing glyph is a share icon
                // rather than a chevron so the row does not promise a screen
                // it never opens.
                trailing: const Icon(
                  Icons.ios_share_rounded,
                  color: AppColors.onSurfaceVariant,
                ),
                onTap: () => _export(context),
              ),

              // ── Support & legal ──────────────────────────────────────────
              const SizedBox(height: AppSpacing.lg),
              AppSectionHeader(title: context.tr('section_support_legal')),
              const SizedBox(height: AppSpacing.sm),
              AppActionTile(
                key: const Key('settings_faq_row'),
                icon: Icons.help_outline_rounded,
                title: context.tr('section_help_faq'),
                subtitle: context.tr('faq_title'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FaqScreen()),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppActionTile(
                key: const Key('settings_feedback_row'),
                icon: Icons.feedback_outlined,
                title: context.tr('send_feedback'),
                subtitle: context.tr('feedback_title'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FeedbackScreen(
                      user: currentUser,
                      submitFeedbackUseCase: submitFeedbackUseCase,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppActionTile(
                key: const Key('settings_terms_privacy_row'),
                icon: Icons.policy_outlined,
                title: context.tr('section_terms_privacy'),
                subtitle: '${context.tr('terms_of_service')} '
                    '${context.tr('and_connector')} '
                    '${context.tr('privacy_policy')}',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsPrivacyScreen()),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Text(
                  'CropCare v1.0.0 (Build 1)\n${context.tr('splash_subtitle')}',
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// Profile header
// =============================================================================

/// Identity at the top of the tab, rather than a settings row that happens to
/// be first. A guest sees the one fact that matters to them — their scans are
/// only on this phone — without opening anything.
class _ProfileHeader extends StatelessWidget {
  final LocalUser? user;
  final VoidCallback? onTap;

  const _ProfileHeader({required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGuest = user?.isGuest ?? true;
    final displayId = user?.email ?? user?.phoneNumber;

    return AppCard(
      key: const Key('settings_profile_row'),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isGuest
                      ? AppColors.surfaceVariant
                      : AppColors.primaryContainer,
                  borderRadius: AppRadius.md,
                ),
                child: Icon(
                  isGuest ? Icons.person_outline_rounded : Icons.person_rounded,
                  size: 28,
                  color: isGuest
                      ? AppColors.onSurfaceVariant
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('profile_title'),
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      displayId ?? context.tr('account_guest_desc'),
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.smPlus),
          Align(
            alignment: Alignment.centerLeft,
            child: isGuest
                ? AppStatusChip(
                    icon: Icons.phone_android_rounded,
                    label: context.tr('guest_badge'),
                    foreground: AppColors.onWarningContainer,
                    background: AppColors.warningContainer,
                  )
                : AppStatusChip(
                    icon: Icons.cloud_done_rounded,
                    label: context.tr('account_linked_badge'),
                    foreground: AppColors.onSuccessContainer,
                    background: AppColors.successContainer,
                  ),
          ),
        ],
      ),
    );
  }
}
