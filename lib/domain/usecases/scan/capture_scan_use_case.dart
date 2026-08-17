import '../../entities/scan.dart';
import '../../repositories/scan_repository.dart';

class CaptureScanUseCase {
  final ScanRepository repository;

  CaptureScanUseCase(this.repository);

  Future<Scan> call({
    required String cropId,
    required String imageLocalPath,
    required String userId,
  }) async {
    return await repository.createScan(
      cropId: cropId,
      imageLocalPath: imageLocalPath,
      userId: userId,
    );
  }
}
