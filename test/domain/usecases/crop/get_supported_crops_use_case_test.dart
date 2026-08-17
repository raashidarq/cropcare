import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/domain/entities/crop.dart';
import 'package:cropcare/domain/repositories/crop_repository.dart';
import 'package:cropcare/domain/usecases/crop/get_supported_crops_use_case.dart';

class FakeCropRepository implements CropRepository {
  final List<Crop> crops;

  FakeCropRepository(this.crops);

  @override
  Future<List<Crop>> getSupportedCrops() async {
    return crops;
  }
}

void main() {
  test('GetSupportedCropsUseCase returns correct seeded list of crops', () async {
    final seededCrops = [
      const Crop(id: 'tomato', nameEn: 'Tomato', nameSi: 'තක්කාලි', nameTa: 'தக்காளி'),
      const Crop(id: 'chili', nameEn: 'Chili', nameSi: 'මිරිස්', nameTa: 'மிளகாய்'),
      const Crop(id: 'paddy', nameEn: 'Paddy / Rice', nameSi: 'ගොයම්', nameTa: 'நெல்'),
    ];

    final fakeRepo = FakeCropRepository(seededCrops);
    final useCase = GetSupportedCropsUseCase(fakeRepo);

    final result = await useCase();

    expect(result.length, equals(3));
    expect(result[0].id, equals('tomato'));
    expect(result[1].id, equals('chili'));
    expect(result[2].id, equals('paddy'));
  });
}
