import '../../entities/crop.dart';
import '../../repositories/crop_repository.dart';

class GetSupportedCropsUseCase {
  final CropRepository repository;

  GetSupportedCropsUseCase(this.repository);

  Future<List<Crop>> call() async {
    return await repository.getSupportedCrops();
  }
}
