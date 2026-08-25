// lib/domain/usecases/history/delete_all_local_scans_use_case.dart

import '../../repositories/scan_repository.dart';

class DeleteAllLocalScansUseCase {
  final ScanRepository repository;

  DeleteAllLocalScansUseCase(this.repository);

  Future<void> call() async {
    await repository.deleteAllLocalScans();
  }
}
