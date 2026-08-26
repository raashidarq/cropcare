// lib/services/work_manager_helper.dart

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../data/local/database/app_database.dart';
import '../data/remote/auth_api_client.dart';
import '../data/remote/sync_api_client.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/local_user_repository_impl.dart';
import '../data/repositories/sync_repository_impl.dart';

/// Unique task name used to identify the periodic sync work in WorkManager.
const _kSyncTaskName = 'cropcare_sync_task';

/// Unique task identifier tag.
const _kSyncTaskUniqueName = 'cropcare_periodic_outbox_flush';

// ---------------------------------------------------------------------------
// Background isolate entry-point
// ---------------------------------------------------------------------------

/// Called by WorkManager in a **separate Dart isolate** when the periodic
/// task fires. All DI must be self-contained here — no access to the main
/// isolate's state.
///
/// The `@pragma('vm:entry-point')` annotation prevents tree-shaking from
/// removing this function in release builds.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _kSyncTaskName) return Future.value(true);

    try {
      WidgetsFlutterBinding.ensureInitialized();

      // ── Minimal DI ──────────────────────────────────────────────────────
      final database = AppDatabase();
      final localUserRepository = LocalUserRepositoryImpl(database);
      final authRepository = AuthRepositoryImpl(
        apiClient: AuthApiClient(),
        localUserRepository: localUserRepository,
      );
      final syncRepository = SyncRepositoryImpl(
        db: database,
        apiClient: SyncApiClient(),
      );

      // ── Token guard (same logic as SyncCubit) ──────────────────────────
      final token = await authRepository.getStoredToken();
      if (token == null || token.isEmpty) {
        // Guest user — nothing to sync.
        await database.close();
        return true;
      }

      // ── Recover interrupted work ────────────────────────────────────────
      // This isolate can be killed mid-batch when WorkManager's execution
      // budget runs out, stranding an operation in IN_PROGRESS. Whichever
      // entry point runs next must reclaim it — that may well be this one
      // rather than app startup, since the worker fires without the app.
      await syncRepository.recoverStalledOperations();

      // ── Outbox flush ────────────────────────────────────────────────────
      // syncPendingOperations takes a DB-backed advisory lock, so if the
      // user happens to be syncing in the foreground right now this returns
      // without double-processing the same rows.
      final count = await syncRepository.getPendingCount();
      if (count > 0) {
        await syncRepository.syncPendingOperations(authToken: token);
      }

      // Reference data sync is best-effort; failures are non-fatal.
      try {
        await syncRepository.syncReferenceData(authToken: token);
      } catch (_) {}

      await database.close();
      return true;
    } catch (_) {
      // Returning false signals WorkManager to retry with back-off.
      return false;
    }
  });
}

// ---------------------------------------------------------------------------
// Helper class used from the main isolate
// ---------------------------------------------------------------------------

class WorkManagerHelper {
  WorkManagerHelper._();

  /// Must be called once in [main] **before** [runApp].
  /// Registers [callbackDispatcher] as the background isolate entry-point.
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  /// Enqueues a periodic outbox flush constrained to when the device has an
  /// active network connection. WorkManager enforces a minimum of 15 minutes.
  static Future<void> scheduleSyncWork() async {
    await Workmanager().registerPeriodicTask(
      _kSyncTaskUniqueName,
      _kSyncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
  }

  /// Cancels the scheduled periodic task. Call this on sign-out.
  static Future<void> cancelSyncWork() async {
    await Workmanager().cancelByUniqueName(_kSyncTaskUniqueName);
  }
}
