// Wi-Fi-only sync.
//
// Scans are full-resolution photographs. Uploading them silently in the
// background over mobile data spends a farmer's money without asking, which
// is the worst way to spend it. The distinction this enforces: automatic
// syncing waits for an unmetered connection, an explicit "Sync now" never
// does — that tap IS the farmer asking.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/application/sync/sync_cubit.dart';
import 'package:cropcare/data/local/preferences/sync_preferences.dart';
import 'package:cropcare/domain/entities/sync_operation.dart';
import 'package:cropcare/domain/repositories/auth_repository.dart';
import 'package:cropcare/domain/repositories/sync_repository.dart';
import 'package:cropcare/services/connectivity_service.dart';

class _FakeSyncRepository implements SyncRepository {
  int syncCalls = 0;

  @override
  Future<void> syncPendingOperations({required String authToken}) async {
    syncCalls++;
  }

  // Non-zero: syncNow short-circuits when there is nothing queued, which is
  // correct behaviour but would make this fake untestable.
  @override
  Future<int> getPendingCount() async => 3;

  @override
  Future<List<SyncOperation>> getFailedOperations() async => [];

  @override
  Future<int> recoverStalledOperations() async => 0;
  @override
  Future<int> restoreScansFromCloud({
    required String userId,
    required String authToken,
    void Function(int restored, int total)? onProgress,
  }) async =>
      0;

  @override
  Future<bool> deleteRemoteScan({
    required String remoteScanId,
    required String authToken,
  }) async =>
      true;


  @override
  Future<void> syncReferenceData({required String authToken}) async {}

  @override
  Future<void> enqueueOperation({
    required String entityId,
    required SyncEntityType entityType,
    required Map<String, dynamic> payload,
    String operationType = 'CREATE',
  }) async {}

  @override
  Future<List<SyncOperation>> getPendingOperations({
    int maxRetries = 3,
    int? limit,
  }) async =>
      [];

  @override
  Future<void> retryOperation(String operationId) async {}

  @override
  Future<void> clearAuthHold() async {}

  @override
  Future<void> updateOperationStatus({
    required String operationId,
    required SyncOperationStatus status,
    String? error,
  }) async {}
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<String?> getStoredToken() async => 'token-123';

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Reports a connection type the test chooses.
class _FakeConnectivityService implements ConnectivityService {
  bool unmetered;

  _FakeConnectivityService({required this.unmetered});

  @override
  Future<bool> isOnUnmeteredConnection() async => unmetered;

  @override
  Future<bool> isConnected() async => true;

  @override
  Stream<bool> connectivityStream({
    Duration debounce = const Duration(seconds: 3),
  }) =>
      const Stream<bool>.empty();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// In-memory preferences, so nothing touches secure storage.
class _FakePrefs implements SyncPreferences {
  bool auto = true;
  bool wifi = true;

  @override
  Future<bool> getAutoSyncEnabled() async => auto;

  @override
  Future<void> setAutoSyncEnabled(bool enabled) async => auto = enabled;

  @override
  Future<bool> getWifiOnly() async => wifi;

  @override
  Future<void> setWifiOnly(bool enabled) async => wifi = enabled;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeSyncRepository sync;
  late _FakePrefs prefs;

  SyncCubit build({required bool unmetered}) {
    sync = _FakeSyncRepository();
    return SyncCubit(
      syncRepository: sync,
      authRepository: _FakeAuthRepository(),
      connectivityService: _FakeConnectivityService(unmetered: unmetered),
      syncPreferences: prefs,
      autoSyncEnabled: true,
    );
  }

  setUp(() => prefs = _FakePrefs());

  test('Wi-Fi-only defaults on: opting into background sync is not opting '
      'into paying for it', () async {
    expect(await prefs.getWifiOnly(), isTrue);
    final cubit = build(unmetered: true);
    await cubit.loadAutoSyncPreference();
    expect(cubit.wifiOnly, isTrue);
  });

  test('an explicit Sync now uploads on mobile data', () async {
    final cubit = build(unmetered: false);
    await cubit.loadAutoSyncPreference();

    await cubit.syncNow();

    // The tap IS the farmer asking. Second-guessing it would be patronising.
    expect(sync.syncCalls, 1);
  });

  test('the preference persists', () async {
    final cubit = build(unmetered: true);
    await cubit.loadAutoSyncPreference();

    await cubit.toggleWifiOnly(false);
    expect(await prefs.getWifiOnly(), isFalse);
    expect(cubit.state.wifiOnly, isFalse);

    await cubit.toggleWifiOnly(true);
    expect(await prefs.getWifiOnly(), isTrue);
    expect(cubit.state.wifiOnly, isTrue);
  });

  test('the state carries it so the toggle renders correctly', () async {
    final cubit = build(unmetered: true);
    await cubit.loadAutoSyncPreference();
    expect(cubit.state.wifiOnly, isTrue);
  });

  test('turning it off is remembered across a reload', () async {
    var cubit = build(unmetered: false);
    await cubit.loadAutoSyncPreference();
    await cubit.toggleWifiOnly(false);

    cubit = build(unmetered: false);
    await cubit.loadAutoSyncPreference();
    expect(cubit.wifiOnly, isFalse);
  });

  test('unmetered detection treats wifi, ethernet and vpn as free', () {
    expect(ConnectivityService.isUnmetered([ConnectivityResult.wifi]), isTrue);
    expect(
        ConnectivityService.isUnmetered([ConnectivityResult.ethernet]), isTrue);
    expect(ConnectivityService.isUnmetered([ConnectivityResult.vpn]), isTrue);
  });

  test('mobile data is not treated as free', () {
    // The whole point. A phone hotspot reports as wifi and is metered, so
    // this is a heuristic — but it beats treating every connection as free.
    expect(
      ConnectivityService.isUnmetered([ConnectivityResult.mobile]),
      isFalse,
    );
    expect(ConnectivityService.isUnmetered([ConnectivityResult.none]), isFalse);
  });
}
