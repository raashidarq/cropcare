// test/presentation/settings/offline_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cropcare/application/sync/sync_cubit.dart';
import 'package:cropcare/domain/entities/local_user.dart';
import 'package:cropcare/domain/entities/sync_operation.dart';
import 'package:cropcare/domain/repositories/auth_repository.dart';
import 'package:cropcare/domain/repositories/sync_repository.dart';
import 'package:cropcare/presentation/onboarding/localization/localization_provider.dart';
import 'package:cropcare/presentation/settings/offline_screen.dart';

class _FakeSyncRepository implements SyncRepository {
  int pendingCount = 0;

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
  Future<int> recoverStalledOperations() async => 0;

  @override
  Future<List<SyncOperation>> getFailedOperations() async => [];

  @override
  Future<void> retryOperation(String operationId) async {}

  @override
  Future<void> clearAuthHold() async {}

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
    pendingCount = 0;
  }
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
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<String?> getStoredToken() async => 'test-token';

  @override
  Future<LocalUser> deleteAccount({required String currentUserId}) => throw UnimplementedError();

  @override
  Future<LocalUser> loginAndUpgradeGuest({required String localUserId, required String email, required String password}) => throw UnimplementedError();

  @override
  Future<LocalUser> registerAndUpgradeGuest({required String localUserId, required String email, required String password}) => throw UnimplementedError();

  @override
  Future<void> requestPasswordReset({required String email}) => throw UnimplementedError();

  @override
  Future<void> requestPhoneChangeOtp({required String newPhoneNumber}) => throw UnimplementedError();

  @override
  Future<void> requestPhoneOtp({required String phoneNumber}) => throw UnimplementedError();

  @override
  Future<void> sendFeedback({required String message, String? category, String? userId}) => throw UnimplementedError();

  @override
  Future<LocalUser> signOut({required String currentUserId}) => throw UnimplementedError();

  @override
  Future<LocalUser> updateEmail({required String currentUserId, required String newEmail}) => throw UnimplementedError();

  @override
  Future<LocalUser> verifyPhoneChangeOtp({required String currentUserId, required String newPhoneNumber, required String otpCode}) => throw UnimplementedError();

  @override
  Future<LocalUser> verifyPhoneOtpAndUpgrade({required String localUserId, required String phoneNumber, required String otpCode}) => throw UnimplementedError();
}

void main() {
  late _FakeSyncRepository fakeSyncRepo;
  late _FakeAuthRepository fakeAuthRepo;
  late SyncCubit syncCubit;

  setUp(() {
    fakeSyncRepo = _FakeSyncRepository();
    fakeAuthRepo = _FakeAuthRepository();
    syncCubit = SyncCubit(
      syncRepository: fakeSyncRepo,
      authRepository: fakeAuthRepo,
    );
  });

  tearDown(() {
    syncCubit.close();
  });

  Widget buildTestScreen() {
    return LocalizationProvider(
      languageCode: 'en',
      child: MaterialApp(
        home: BlocProvider.value(
          value: syncCubit,
          child: const OfflineScreen(),
        ),
      ),
    );
  }

  testWidgets('OfflineScreen renders all components', (tester) async {
    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    expect(find.text('Offline & Storage'), findsOneWidget);
    expect(find.byKey(const Key('offline_sync_status_card')), findsOneWidget);
    expect(find.byKey(const Key('offline_sync_now_button')), findsOneWidget);
    expect(find.byKey(const Key('offline_auto_sync_switch')), findsOneWidget);
    expect(find.byKey(const Key('offline_delete_scans_row')), findsOneWidget);
  });

  testWidgets(
    'auto sync starts off and its switch is disabled without an account',
    (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Off by default — it uploads photos over a metered connection.
      expect(syncCubit.autoSyncEnabled, isFalse);

      // No user is supplied to the screen, so this is the guest case: the
      // switch is inert rather than accepting a setting that cannot apply.
      final switchWidget = tester.widget<SwitchListTile>(
        find.byKey(const Key('offline_auto_sync_switch')),
      );
      expect(switchWidget.onChanged, isNull);
    },
  );

  testWidgets('Tapping delete when pendingCount == 0 opens confirm_delete_dialog', (tester) async {
    fakeSyncRepo.pendingCount = 0;
    await syncCubit.refreshPendingCount();

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('offline_delete_scans_row')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('confirm_delete_dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm_delete_button')));
    await tester.pumpAndSettle();

    expect(find.text('All local scans have been deleted.'), findsOneWidget);
  });

  testWidgets('Tapping delete when pendingCount > 0 opens unsynced_warning_dialog', (tester) async {
    fakeSyncRepo.pendingCount = 3;
    await syncCubit.refreshPendingCount();

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('offline_delete_scans_row')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('unsynced_warning_dialog')), findsOneWidget);
    expect(find.byKey(const Key('sync_first_button')), findsOneWidget);
    expect(find.byKey(const Key('delete_anyway_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete_anyway_button')));
    await tester.pumpAndSettle();

    expect(find.text('All local scans have been deleted.'), findsOneWidget);
  });
}
