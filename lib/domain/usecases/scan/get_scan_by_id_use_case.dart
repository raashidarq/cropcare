import '../../entities/scan.dart';
import '../../repositories/scan_repository.dart';

class GetScanByIdUseCase {
  final ScanRepository repository;

  GetScanByIdUseCase(this.repository);

  Future<Scan?> call(String id) async {
    return await repository.getScanById(id);
  }
}
