// lib/presentation/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/auth/auth_cubit.dart';
import '../../application/onboarding/app_state_cubit.dart';
import '../../application/settings/settings_cubit.dart';
import '../../application/settings/settings_state.dart';
import '../../application/sync/sync_cubit.dart';
import '../../application/sync/sync_state.dart';
import '../../domain/entities/local_user.dart';
import '../auth/auth_screen.dart';
import '../onboarding/localization/localization_provider.dart';
import '../onboarding/widgets/change_language_dialog.dart';

class SettingsScreen extends StatelessWidget {
  final LocalUser? user;
  final AuthCubit? authCubit;
  final SyncCubit? syncCubit;

  const SettingsScreen({
    super.key,
    this.user,
    this.authCubit,
    this.syncCubit,
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
      ),
    );
  }
}

class _SettingsView extends StatelessWidget {
  final LocalUser? user;
  final AuthCubit? authCubit;
  final SyncCubit? syncCubit;

  const _SettingsView({
    this.user,
    this.authCubit,
    this.syncCubit,
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
    final email = currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings_title')),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              // ── Account Section ──────────────────────────────────────────
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  key: const Key('settings_account_row'),
                  leading: CircleAvatar(
                    backgroundColor: isGuest
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.primaryContainer,
                    child: Icon(
                      isGuest ? Icons.person_outline : Icons.account_circle,
                      color: isGuest
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    context.tr('account_section'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isGuest
                        ? context.tr('account_guest_desc')
                        : '${context.tr('signed_in_as')}: $email',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: isGuest
                      ? ElevatedButton(
                          key: const Key('settings_link_account_button'),
                          style: ElevatedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            if (currentUser != null && authCubit != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: authCubit!,
                                    child: AuthScreen(currentUser: currentUser),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(context.tr('link_account_btn')),
                        )
                      : TextButton(
                          key: const Key('settings_sign_out_button'),
                          onPressed: () => authCubit?.signOut(),
                          child: Text(context.tr('sign_out')),
                        ),
                ),
              ),

              // ── Language Section ─────────────────────────────────────────
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

              // ── Accessibility Section ────────────────────────────────────
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                  subtitle: Text(context.tr('coming_soon')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showComingSoonDialog(
                    context,
                    'section_accessibility',
                  ),
                ),
              ),

              // ── Notifications Section ────────────────────────────────────
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

              // ── Offline Data & Cloud Sync Section ───────────────────────
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: BlocConsumer<SyncCubit, SyncState>(
                  listener: (context, syncState) {
                    if (syncState is SyncSuccess && syncState.syncedCount > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.tr('sync_success')),
                          backgroundColor: Colors.green.shade700,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else if (syncState is SyncError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(syncState.message),
                          backgroundColor: Colors.red.shade700,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  builder: (context, syncState) {
                    final isSyncing = syncState is SyncInProgress;
                    final pendingCount = syncState.pendingCount;

                    return ListTile(
                      key: const Key('settings_offline_data_row'),
                      leading: CircleAvatar(
                        backgroundColor: pendingCount > 0
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          pendingCount > 0
                              ? Icons.cloud_upload_outlined
                              : Icons.cloud_done_outlined,
                          color: pendingCount > 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      title: Text(
                        context.tr('section_offline_data'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isSyncing
                            ? context.tr('sync_in_progress')
                            : pendingCount > 0
                                ? '$pendingCount ${context.tr('sync_pending')}'
                                : context.tr('sync_offline_ready'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: ElevatedButton(
                        key: const Key('settings_sync_now_button'),
                        style: ElevatedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: isSyncing
                            ? null
                            : () {
                                context.read<SyncCubit>().syncNow();
                              },
                        child: isSyncing
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                context.tr('sync_now'),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
