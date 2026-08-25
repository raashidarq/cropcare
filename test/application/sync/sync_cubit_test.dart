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
  Future<List<SyncOperation>> getPendingOperations({int maxRetries = 3}) async => [];

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
  Future<LocalUser> signOut({required String currentUserId}) =>
      throw UnimplementedError();
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
  });
}
