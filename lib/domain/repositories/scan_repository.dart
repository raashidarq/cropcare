import '../entities/scan.dart';

abstract class ScanRepository {
  Future<Scan> createScan({
    required String cropId,
    required String imageLocalPath,
    required String userId,
  });

  Future<Scan?> getScanById(String id);
}
