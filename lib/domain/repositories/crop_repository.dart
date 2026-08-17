import '../entities/crop.dart';

abstract class CropRepository {
  Future<List<Crop>> getSupportedCrops();
}
