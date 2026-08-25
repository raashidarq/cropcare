// lib/presentation/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/auth/auth_cubit.dart';
import '../../application/onboarding/app_state_cubit.dart';
import '../../application/settings/settings_cubit.dart';
import '../../application/settings/settings_state.dart';
import '../../application/sync/sync_cubit.dart';
import '../../domain/entities/local_user.dart';
import '../../domain/usecases/feedback/submit_feedback_use_case.dart';
import '../../domain/usecases/history/export_scan_history_use_case.dart';
import '../onboarding/localization/localization_provider.dart';
import '../onboarding/widgets/change_language_dialog.dart';
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
        if (syncCubit != null) BlocProvider.value(value: syncCubit!..refreshPendingCount()),
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

  void _showComingSoonDialog(BuildContext context, String titleKey) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr(titleKey)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.construction,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('coming_soon'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('coming_soon_desc'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String titleKey) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        context.tr(titleKey).toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLang = context.watch<AppStateCubit>().state.languageCode;

    String currentLangName = context.tr('lang_english');
    if (currentLang == 'si') {
      currentLangName = context.tr('lang_sinhala');
    } else if (currentLang == 'ta') {
      currentLangName = context.tr('lang_tamil');
    }

    final currentUser = authCubit?.currentUser ?? user;
    final isGuest = currentUser?.isGuest ?? true;
    final displayId = currentUser?.email ?? currentUser?.phoneNumber ?? context.tr('guest_badge');

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings_title')),
        elevation: 0,
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // ── 1. Profile & Account Section ─────────────────────────────
              _buildSectionHeader(context, 'section_profile'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  key: const Key('settings_profile_row'),
                  leading: CircleAvatar(
                    backgroundColor: isGuest
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.primaryContainer,
                    child: Icon(
                      isGuest ? Icons.person_outline : Icons.person,
                      color: isGuest
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    context.tr('profile_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isGuest ? context.tr('account_guest_desc') : displayId,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (currentUser != null && authCubit != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: authCubit!,
                            child: ProfileScreen(
                              user: currentUser,
                              authCubit: authCubit,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),

              // ── 2. Preferences Section ───────────────────────────────────
              _buildSectionHeader(context, 'section_preferences'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  key: const Key('settings_language_row'),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.language, color: theme.colorScheme.primary),
                  ),
                  title: Text(
                    context.tr('section_language'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(currentLangName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ChangeLanguageDialog.show(context),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  key: const Key('settings_notifications_row'),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                    child: Icon(Icons.notifications_none,
                        color: theme.colorScheme.tertiary),
                  ),
                  title: Text(
                    context.tr('section_notifications'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(context.tr('coming_soon')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showComingSoonDialog(
                    context,
                    'section_notifications',
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  key: const Key('settings_accessibility_row'),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(Icons.accessibility_new,
                        color: theme.colorScheme.secondary),
                  ),
                  title: Text(
                    context.tr('section_accessibility'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    context.tr('accessibility_subtitle'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccessibilityScreen(),
                      ),
                    );
                  },
                ),
              ),

              // ── 3. Data & Storage Section ────────────────────────────────
              _buildSectionHeader(context, 'section_data_storage'),
              _buildOfflineRow(context, theme),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  key: const Key('settings_export_data_row'),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                    child: Icon(Icons.file_download_outlined,
                        color: theme.colorScheme.onTertiaryContainer),
                  ),
                  title: Text(
                    context.tr('export_data_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    context.tr('export_data_desc'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: TextButton.icon(
                    key: const Key('settings_export_button'),
                    icon: const Icon(Icons.share, size: 16),
                    label: Text(context.tr('export_data_btn')),
                    onPressed: () async {
                      if (exportScanHistoryUseCase != null) {
                        final count = await exportScanHistoryUseCase!.execute();
                        if (context.mounted) {
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
                      }
                    },
                  ),
                  onTap: () async {
                    if (exportScanHistoryUseCase != null) {
                      final count = await exportScanHistoryUseCase!.execute();
                      if (context.mounted) {
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
                    }
                  },
                ),
              ),

              // ── 4. Support & Legal Section ───────────────────────────────
              _buildSectionHeader(context, 'section_support_legal'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  key: const Key('settings_faq_row'),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.help_outline,
                        color: theme.colorScheme.primary),
                  ),
                  title: Text(
                    context.tr('section_help_faq'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    context.tr('faq_title'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FaqScreen(),
                      ),
                    );
                  },
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  key: const Key('settings_feedback_row'),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(Icons.feedback_outlined,
                        color: theme.colorScheme.secondary),
                  ),
                  title: Text(
                    context.tr('send_feedback'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    context.tr('feedback_title'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FeedbackScreen(
                          user: currentUser,
                          submitFeedbackUseCase: submitFeedbackUseCase,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  key: const Key('settings_terms_privacy_row'),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.policy_outlined,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  title: Text(
                    context.tr('section_terms_privacy'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${context.tr('terms_of_service')} ${context.tr('and_connector')} ${context.tr('privacy_policy')}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsPrivacyScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ── App Footer ───────────────────────────────────────────────
              Center(
                child: Text(
                  'CropCare v1.0.0 (Build 1)\n${context.tr('splash_subtitle')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOfflineRow(BuildContext context, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        key: const Key('settings_offline_data_row'),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.cloud_sync_outlined,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          context.tr('section_offline'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          context.tr('offline_subtitle'),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => syncCubit != null
                  ? BlocProvider.value(
                      value: syncCubit!,
                      child: const OfflineScreen(),
                    )
                  : const OfflineScreen(),
            ),
          );
        },
      ),
    );
  }
}
