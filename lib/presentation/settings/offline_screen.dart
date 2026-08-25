// lib/presentation/settings/offline_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/sync/sync_cubit.dart';
import '../../application/sync/sync_state.dart';
import '../onboarding/localization/localization_provider.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  void _showUnsyncedWarningDialog(BuildContext context, int pendingCount) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        key: const Key('unsynced_warning_dialog'),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
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
            child: Text(context.tr('cancel_btn')),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
            child: Text(context.tr('cancel_btn')),
          ),
          ElevatedButton(
            key: const Key('confirm_delete_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is SyncError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
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
                                ? Colors.amber.shade100
                                : Colors.green.shade100,
                            radius: 24,
                            child: Icon(
                              pendingCount > 0
                                  ? Icons.cloud_upload_outlined
                                  : Icons.cloud_done,
                              color: pendingCount > 0
                                  ? Colors.amber.shade900
                                  : Colors.green.shade800,
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
                                        AlwaysStoppedAnimation<Color>(Colors.white),
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
                    context.tr('auto_sync_desc'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: autoSync,
                  onChanged: (val) {
                    cubit.toggleAutoSync(val);
                  },
                ),
              ),

              // ── 3. Local Storage Management ──────────────────────────────
              _buildSectionHeader(context, 'section_data_storage'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  key: const Key('offline_delete_scans_row'),
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade50,
                    child: const Icon(
                      Icons.delete_sweep_outlined,
                      color: Colors.red,
                    ),
                  ),
                  title: Text(
                    context.tr('delete_local_scans_title'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  subtitle: Text(
                    context.tr('delete_local_scans_desc'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.red),
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
