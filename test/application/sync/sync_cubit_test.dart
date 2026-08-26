import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/application/sync/sync_cubit.dart';
import 'package:cropcare/application/sync/sync_state.dart';
import 'package:cropcare/domain/entities/local_user.dart';
import 'package:cropcare/domain/entities/sync_operation.dart';
import 'package:cropcare/domain/repositories/auth_repository.dart';
import 'package:cropcare/domain/repositories/sync_repository.dart';

class _FakeSyncRepository implements SyncRepository {
  int pendingCount = 2;
  String? lastAuthToken;

  @override
  Future<void> enqueueOperation({
    required String entityId,
    required SyncEntityType entityType,
    required Map<String, dynamic> payload,
    String operationType = 'CREATE',
  }) async {
    pendingCount++;
  }

  @override
  Future<List<SyncOperation>> getPendingOperations({
    int maxRetries = 3,
    int? limit,
  }) async =>
      [];

  @override
  Future<int> recoverStalledOperations() async => 0;

  List<SyncOperation> failedOperations = [];
  final List<String> retriedOperationIds = [];
  int clearAuthHoldCalls = 0;

  @override
  Future<List<SyncOperation>> getFailedOperations() async => failedOperations;

  @override
  Future<void> retryOperation(String operationId) async {
    retriedOperationIds.add(operationId);
    failedOperations =
        failedOperations.where((o) => o.id != operationId).toList();
    pendingCount++;
  }

  @override
  Future<void> clearAuthHold() async {
    clearAuthHoldCalls++;
    failedOperations = failedOperations
        .where((o) => o.status != SyncOperationStatus.authRequired)
        .toList();
  }

  @override
  Future<int> getPendingCount() async => pendingCount;

  @override
  Future<void> updateOperationStatus({
    required String operationId,
    required SyncOperationStatus status,
    String? error,
  }) async {}

  @override
  Future<void> syncPendingOperations({required String authToken}) async {
    lastAuthToken = authToken;
    pendingCount = 0;
  }

  @override
  Future<void> syncReferenceData({required String authToken}) async {}
}

class _FakeAuthRepository implements AuthRepository {
  String? storedToken;

  @override
  Future<String?> getStoredToken() async => storedToken;

  @override
  Future<LocalUser> loginAndUpgradeGuest({
    required String localUserId,
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<LocalUser> registerAndUpgradeGuest({
    required String localUserId,
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<LocalUser> signOut({required String currentUserId}) async {
    return LocalUser(
      id: currentUserId,
      isGuest: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> requestPhoneOtp({required String phoneNumber}) async {}

  @override
  Future<LocalUser> verifyPhoneOtpAndUpgrade({
    required String localUserId,
    required String phoneNumber,
    required String otpCode,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<LocalUser> deleteAccount({required String currentUserId}) async {
    return LocalUser(
      id: currentUserId,
      isGuest: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> sendFeedback({
    required String message,
    String? category,
    String? userId,
  }) async {}

  @override
  Future<LocalUser> updateEmail({required String currentUserId, required String newEmail}) => throw UnimplementedError();

  @override
  Future<void> requestPhoneChangeOtp({required String newPhoneNumber}) async {}

  @override
  Future<LocalUser> verifyPhoneChangeOtp({required String currentUserId, required String newPhoneNumber, required String otpCode}) => throw UnimplementedError();
}

void main() {
  group('SyncCubit', () {
    late _FakeSyncRepository fakeSyncRepo;
    late _FakeAuthRepository fakeAuthRepo;
    late SyncCubit cubit;

    setUp(() {
      fakeSyncRepo = _FakeSyncRepository();
      fakeAuthRepo = _FakeAuthRepository();
      cubit = SyncCubit(
        syncRepository: fakeSyncRepo,
        authRepository: fakeAuthRepo,
      );
    });

    test('refreshPendingCount emits SyncInitial with current pending count', () async {
      await cubit.refreshPendingCount();
      expect(cubit.state.pendingCount, 2);
    });

    test('syncNow prompts for auth when token is null or empty', () async {
      fakeAuthRepo.storedToken = null;

      await cubit.syncNow();
      expect(cubit.state, isA<SyncError>());
      expect((cubit.state as SyncError).message, contains('Please link or sign in'));
    });

    test('syncNow processes pending items when user is authenticated with token', () async {
      fakeAuthRepo.storedToken = 'valid_jwt_token';

      final states = <SyncState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(states.any((s) => s is SyncInProgress), isTrue);
      expect(cubit.state, isA<SyncSuccess>());
      expect((cubit.state as SyncSuccess).syncedCount, 2);
      expect((cubit.state as SyncSuccess).pendingCount, 0);
      expect(fakeSyncRepo.lastAuthToken, 'valid_jwt_token');

      await sub.cancel();
    });

    test('auto-sync is off by default', () {
      // Opt-in: syncing uploads photos over a frequently metered connection,
      // and a guest has no account to sync to.
      expect(cubit.state.autoSyncEnabled, isFalse);
    });

    test('enabling auto-sync requires a signed-in session', () async {
      fakeAuthRepo.storedToken = null;
      await cubit.toggleAutoSync(true);
      expect(cubit.autoSyncEnabled, isFalse);
      expect(cubit.state, isA<SyncError>());

      fakeAuthRepo.storedToken = 'token-123';
      await cubit.toggleAutoSync(true);
      expect(cubit.autoSyncEnabled, isTrue);
      expect(cubit.state.autoSyncEnabled, isTrue);
    });

    test('disabling auto-sync always works', () async {
      fakeAuthRepo.storedToken = 'token-123';
      await cubit.toggleAutoSync(true);
      await cubit.toggleAutoSync(false);
      expect(cubit.autoSyncEnabled, isFalse);
      expect(cubit.state.autoSyncEnabled, isFalse);
    });

    test('signing out clears auto-sync so a later guest does not inherit it',
        () async {
      fakeAuthRepo.storedToken = 'token-123';
      await cubit.toggleAutoSync(true);
      await cubit.disableAutoSyncOnSignOut();
      expect(cubit.autoSyncEnabled, isFalse);
    });

    test('deleteAllLocalScans resets pendingCount to 0', () async {
      await cubit.refreshPendingCount();
      expect(cubit.state.pendingCount, 2);
      await cubit.deleteAllLocalScans();
      expect(cubit.state.pendingCount, 0);
    });
  });

  group('SyncCubit failed operations', () {
    SyncOperation op(String id, SyncOperationStatus status) => SyncOperation(
          id: id,
          entityId: 'entity-$id',
          entityType: SyncEntityType.scan,
          payloadJson: '{}',
          status: status,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );

    test('surfaces operations the engine stopped retrying', () async {
      final repo = _FakeSyncRepository()
        ..failedOperations = [
          op('a', SyncOperationStatus.permanentlyFailed),
        ];
      final cubit = SyncCubit(
        syncRepository: repo,
        authRepository: _FakeAuthRepository(),
      );

      await cubit.refreshPendingCount();

      expect(cubit.state.failedOperations, hasLength(1));
      expect(cubit.state.needsReauth, isFalse);
      await cubit.close();
    });

    test('needsReauth is true only when something is held on auth', () async {
      final repo = _FakeSyncRepository()
        ..failedOperations = [
          op('a', SyncOperationStatus.permanentlyFailed),
          op('b', SyncOperationStatus.authRequired),
        ];
      final cubit = SyncCubit(
        syncRepository: repo,
        authRepository: _FakeAuthRepository(),
      );

      await cubit.refreshPendingCount();

      expect(cubit.state.needsReauth, isTrue);
      await cubit.close();
    });

    test('retrying a failed operation re-queues it and drops it from the list',
        () async {
      final repo = _FakeSyncRepository()
        ..failedOperations = [
          op('a', SyncOperationStatus.permanentlyFailed),
        ];
      final cubit = SyncCubit(
        syncRepository: repo,
        authRepository: _FakeAuthRepository(),
      );
      await cubit.refreshPendingCount();

      await cubit.retryFailedOperation('a');

      expect(repo.retriedOperationIds, ['a']);
      expect(cubit.state.failedOperations, isEmpty);
      await cubit.close();
    });

    test('resumeAfterReauth releases the auth hold before syncing', () async {
      final repo = _FakeSyncRepository()
        ..failedOperations = [op('b', SyncOperationStatus.authRequired)];
      final cubit = SyncCubit(
        syncRepository: repo,
        authRepository: _FakeAuthRepository(),
      );

      await cubit.resumeAfterReauth();

      expect(repo.clearAuthHoldCalls, 1);
      expect(
        cubit.state.failedOperations
            .where((o) => o.status == SyncOperationStatus.authRequired),
        isEmpty,
      );
      await cubit.close();
    });
  });
}
