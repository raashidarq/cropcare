import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/application/history/history_cubit.dart';
import 'package:cropcare/application/history/history_state.dart';
import 'package:cropcare/domain/entities/scan.dart';
import 'package:cropcare/domain/entities/scan_history_item.dart';
import 'package:cropcare/domain/repositories/scan_repository.dart';
import 'package:cropcare/domain/usecases/history/get_scan_history_use_case.dart';

class _FakeScanRepository implements ScanRepository {
  List<ScanHistoryItem> history = [];

  @override
  Future<Scan> createScan({required String cropId, required String imageLocalPath, required String userId}) async {
    throw UnimplementedError();
  }

  @override
  Future<Scan?> getScanById(String id) async => null;

  @override
  Future<void> updateScanStatus(String scanId, ScanStatus status) async {}

  @override
  Future<List<ScanHistoryItem>> getScanHistory() async => history;
}

void main() {
  group('HistoryCubit', () {
    test('loadHistory emits Empty when no scans exist', () async {
      final fakeRepo = _FakeScanRepository()..history = [];
      final useCase = GetScanHistoryUseCase(fakeRepo);
      final cubit = HistoryCubit(getScanHistoryUseCase: useCase);

      final states = <HistoryState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadHistory();
      await Future.delayed(Duration.zero);

      expect(states[0], isA<HistoryLoading>());
      expect(states[1], isA<HistoryEmpty>());

      await sub.cancel();
    });

    test('loadHistory emits Loaded when scans exist', () async {
      final item = ScanHistoryItem(
        scan: Scan(
          id: 's1',
          userId: 'u1',
          cropId: 'tomato',
          imageLocalPath: '/p.jpg',
          status: ScanStatus.diagnosed,
          capturedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final fakeRepo = _FakeScanRepository()..history = [item];
      final useCase = GetScanHistoryUseCase(fakeRepo);
      final cubit = HistoryCubit(getScanHistoryUseCase: useCase);

      final states = <HistoryState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadHistory();
      await Future.delayed(Duration.zero);

      expect(states[0], isA<HistoryLoading>());
      expect(states[1], isA<HistoryLoaded>());
      expect((states[1] as HistoryLoaded).items.length, equals(1));

      await sub.cancel();
    });
  });
}
