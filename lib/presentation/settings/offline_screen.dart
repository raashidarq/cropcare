// lib/presentation/settings/offline_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/auth/auth_cubit.dart';
import '../../application/sync/sync_cubit.dart';
import '../../application/sync/sync_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/local_user.dart';
import '../../domain/entities/sync_operation.dart';
import '../auth/auth_screen.dart';
import '../onboarding/localization/localization_provider.dart';
import '../shared/widgets/app_components.dart';

class OfflineScreen extends StatelessWidget {
  /// Needed only to offer re-authentication when sync operations are held by
  /// an expired session. Optional so the screen still renders (without that
  /// affordance) wherever they are not available.
  final LocalUser? user;
  final AuthCubit? authCubit;

  const OfflineScreen({super.key, this.user, this.authCubit});

  void _showUnsyncedWarningDialog(BuildContext context, int pendingCount) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        key: const Key('unsynced_warning_dialog'),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr('unsynced_warning_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          '$pendingCount ${context.tr('sync_pending_count')}. ${context.tr('unsynced_warning_msg')}',
        ),
        actions: [
          TextButton(
            key: const Key('cancel_delete_button'),
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            key: const Key('sync_first_button'),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<SyncCubit>().syncNow();
            },
            child: Text(context.tr('sync_first_btn')),
          ),
          TextButton(
            key: const Key('delete_anyway_button'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await context.read<SyncCubit>().deleteAllLocalScans();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('all_scans_deleted')),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(context.tr('delete_anyway_btn')),
          ),
        ],
      ),
    );
  }

  void _showConfirmDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        key: const Key('confirm_delete_dialog'),
        title: Text(
          context.tr('delete_scans_confirm_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(context.tr('delete_scans_confirm_msg')),
        actions: [
          TextButton(
            key: const Key('cancel_delete_button'),
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            key: const Key('confirm_delete_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await context.read<SyncCubit>().deleteAllLocalScans();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('all_scans_deleted')),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(context.tr('delete_anyway_btn')),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String titleKey) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
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

  /// Sends the user to sign in, then releases the held queue. Clearing the
  /// hold is the step that actually turns a successful sign-in back into a
  /// working queue — without it the items stay held indefinitely.
  /// Pulls scans back from the cloud.
  ///
  /// Confirms first, because on a rural connection this downloads every photo
  /// the account holds and that is the farmer's data allowance being spent.
  Future<void> _restore(BuildContext context, SyncCubit cubit) async {
    final currentUser = user ?? authCubit?.currentUser;
    if (currentUser == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        key: const Key('restore_confirm_dialog'),
        title: Text(dialogCtx.tr('restore_title')),
        content: Text(dialogCtx.tr('restore_confirm_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(dialogCtx.tr('cancel')),
          ),
          ElevatedButton(
            key: const Key('restore_confirm_button'),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(dialogCtx.tr('restore_action')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Resolved before the await: the context may be gone afterwards.
    final noneMsg = context.tr('restore_none');
    final doneTemplate = context.tr('restore_done');

    final restored = await cubit.restoreFromCloud(userId: currentUser.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          restored == 0
              // Zero is not a failure: it usually means everything in the
              // cloud is already on this phone.
              ? noneMsg
              : doneTemplate.replaceFirst('{count}', '$restored'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleReauth(BuildContext context, SyncCubit cubit) async {
    final currentUser = user ?? authCubit?.currentUser;
    if (currentUser == null || authCubit == null) {
      // Nothing to sign in with from here; clearing the hold at least lets
      // the next successful sync pick the items up.
      await cubit.resumeAfterReauth();
      return;
    }

    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: authCubit!,
          child: AuthScreen(currentUser: currentUser),
        ),
      ),
    );
    await cubit.resumeAfterReauth();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('offline_title')),
        elevation: 0,
      ),
      body: BlocConsumer<SyncCubit, SyncState>(
        listener: (context, state) {
          if (state is SyncSuccess && state.syncedCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr('sync_success')),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is SyncError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<SyncCubit>();
          final isSyncing = state is SyncInProgress;
          final pendingCount = state.pendingCount;
          final autoSync = state.autoSyncEnabled;
          final isSignedIn = !(user?.isGuest ?? true);

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // ── 1. Cloud Sync Status Card ───────────────────────────────
              _buildSectionHeader(context, 'sync_status_title'),
              Card(
                key: const Key('offline_sync_status_card'),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: pendingCount > 0
                                ? AppColors.warningContainer
                                : AppColors.successContainer,
                            radius: 24,
                            child: Icon(
                              pendingCount > 0
                                  ? Icons.cloud_upload_outlined
                                  : Icons.cloud_done,
                              color: pendingCount > 0
                                  ? AppColors.onWarningContainer
                                  : AppColors.success,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pendingCount > 0
                                      ? '$pendingCount ${context.tr('sync_pending_count')}'
                                      : context.tr('sync_all_synced'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isSyncing
                                      ? context.tr('sync_in_progress')
                                      : context.tr('sync_offline_ready'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          key: const Key('offline_sync_now_button'),
                          icon: isSyncing
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                                  ),
                                )
                              : const Icon(Icons.sync),
                          label: Text(
                            isSyncing
                                ? context.tr('sync_in_progress')
                                : context.tr('sync_now'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: isSyncing
                              ? null
                              : () {
                                  cubit.syncNow();
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 1b. Anything the engine stopped retrying ────────────────
              FailedSyncSection(
                operations: state.failedOperations,
                cubit: cubit,
                onSignIn: () => _handleReauth(context, cubit),
              ),

              // ── 1c. Restore ─────────────────────────────────────────────
              // Sits directly above the delete action on purpose: the two are
              // a pair, and seeing that scans can come back is what makes
              // deleting them locally a reasonable thing to do.
              if (isSignedIn)
                Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    key: const Key('offline_restore_row'),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.cloud_download_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      context.tr('restore_title'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      context.tr('restore_desc'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _restore(context, cubit),
                  ),
                ),

              // ── 2. Auto-Sync Settings ───────────────────────────────────
              _buildSectionHeader(context, 'auto_sync_title'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SwitchListTile(
                  key: const Key('offline_auto_sync_switch'),
                  secondary: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.autorenew,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    context.tr('auto_sync_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isSignedIn
                        ? context.tr('auto_sync_desc')
                        : context.tr('auto_sync_requires_account'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: autoSync,
                  // A guest has no account to sync to, so the control is
                  // disabled rather than accepting a setting that cannot
                  // take effect. The subtitle says why.
                  onChanged: isSignedIn
                      ? (val) => cubit.toggleAutoSync(val)
                      : null,
                ),
              ),
              // Only meaningful while auto-sync is on: it governs *when*
              // background syncing runs, and "Sync now" ignores it entirely.
              // Showing it against a disabled auto-sync would suggest it
              // gates the manual action too.
              if (isSignedIn && autoSync)
                Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SwitchListTile(
                    key: const Key('offline_wifi_only_switch'),
                    secondary: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.wifi_rounded,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    title: Text(
                      context.tr('wifi_only_title'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      context.tr('wifi_only_desc'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: state.wifiOnly,
                    onChanged: (val) => cubit.toggleWifiOnly(val),
                  ),
                ),

              // ── 3. Local Storage Management ──────────────────────────────
              _buildSectionHeader(context, 'section_data_storage'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  key: const Key('offline_delete_scans_row'),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.errorContainer,
                    child: const Icon(
                      Icons.delete_sweep_outlined,
                      color: AppColors.error,
                    ),
                  ),
                  title: Text(
                    context.tr('delete_local_scans_title'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  subtitle: Text(
                    context.tr('delete_local_scans_desc'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.error),
                  onTap: () {
                    if (pendingCount > 0) {
                      _showUnsyncedWarningDialog(context, pendingCount);
                    } else {
                      _showConfirmDeleteDialog(context);
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// Failed / held operations
// =============================================================================

/// Operations the sync engine has given up retrying.
///
/// This exists because the engine used to drop them silently: once an
/// operation exhausted its retry budget it was excluded from every future
/// query, so a farmer's scan simply never reached the cloud and nothing ever
/// said so. Anything that stopped retrying is now shown here with a reason
/// and a way to act on it.
class FailedSyncSection extends StatelessWidget {
  final List<SyncOperation> operations;
  final SyncCubit cubit;
  final VoidCallback onSignIn;

  const FailedSyncSection({
    super.key,
    required this.operations,
    required this.cubit,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    if (operations.isEmpty) return const SizedBox.shrink();

    final authHeld = operations
        .where((o) => o.status == SyncOperationStatus.authRequired)
        .toList();
    final permanent = operations
        .where((o) => o.status != SyncOperationStatus.authRequired)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),

          // Session expiry is a different problem from a broken payload: it
          // is fixable by the user, in one step, and fixing it releases the
          // whole held batch at once. It therefore leads.
          if (authHeld.isNotEmpty) ...[
            AppBanner(
              key: const Key('sync_reauth_banner'),
              icon: Icons.lock_outline_rounded,
              title: context.tr('sync_session_expired_title'),
              message: context
                  .tr('sync_session_expired_msg')
                  .replaceFirst('{count}', '${authHeld.length}'),
              foreground: AppColors.onWarningContainer,
              background: AppColors.warningContainer,
              actionLabel: context.tr('sign_in_again'),
              onAction: onSignIn,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          if (permanent.isNotEmpty) ...[
            AppSectionHeader(
              title: context.tr('sync_failed_title'),
              icon: Icons.error_outline_rounded,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr('sync_failed_desc'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.smPlus),
            for (final op in permanent) ...[
              _FailedOperationTile(
                operation: op,
                onRetry: () => cubit.retryFailedOperation(op.id),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _FailedOperationTile extends StatelessWidget {
  final SyncOperation operation;
  final VoidCallback onRetry;

  const _FailedOperationTile({
    required this.operation,
    required this.onRetry,
  });

  String _label(BuildContext context) {
    switch (operation.entityType) {
      case SyncEntityType.scan:
        return context.tr('sync_item_scan');
      case SyncEntityType.diagnosis:
        return context.tr('sync_item_diagnosis');
      case SyncEntityType.escalation:
        return context.tr('sync_item_escalation');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      key: Key('failed_sync_op_${operation.id}'),
      padding: const EdgeInsets.all(AppSpacing.smPlus),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 20,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.smPlus),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_label(context), style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _formatDate(operation.createdAt),
                  style: theme.textTheme.labelSmall,
                ),
                // `lastError` is a raw server/exception string. It is kept
                // out of the primary line deliberately — it is untranslated
                // and meaningless to a farmer — but stays reachable for
                // support.
                if (operation.lastError != null &&
                    operation.lastError!.trim().isNotEmpty)
                  Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      title: Text(
                        context.tr('show_details'),
                        style: theme.textTheme.bodySmall,
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            operation.lastError!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            key: Key('retry_sync_op_${operation.id}'),
            onPressed: onRetry,
            child: Text(context.tr('retry')),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime when) {
    return '${when.year}-${when.month.toString().padLeft(2, '0')}-'
        '${when.day.toString().padLeft(2, '0')}';
  }
}
