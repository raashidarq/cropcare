import 'package:drift/drift.dart';

import '../../domain/entities/crop.dart';
import '../../domain/repositories/crop_repository.dart';
import '../local/database/app_database.dart';

class CropRepositoryImpl implements CropRepository {
  final AppDatabase db;

  CropRepositoryImpl(this.db);

  @override
  Future<List<Crop>> getSupportedCrops() async {
    final crops = await db.select(db.cropTable).get();
    if (crops.isEmpty) {
      await _seedCrops();
      final seeded = await db.select(db.cropTable).get();
      return seeded.map(_mapToEntity).toList();
    }
    return crops.map(_mapToEntity).toList();
  }

  Future<void> _seedCrops() async {
    final seedCrops = [
      CropTableCompanion.insert(
        id: 'tomato',
        nameEn: 'Tomato',
        nameSi: const Value('තක්කාලි'),
        nameTa: const Value('தக்காளி'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/tomato.png'),
      ),
      CropTableCompanion.insert(
        id: 'chili',
        nameEn: 'Chili',
        nameSi: const Value('මිරිස්'),
        nameTa: const Value('மிළගායි'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/chili.png'),
      ),
      CropTableCompanion.insert(
        id: 'paddy',
        nameEn: 'Paddy / Rice',
        nameSi: const Value('ගොයම්'),
        nameTa: const Value('நெல்'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/paddy.png'),
      ),
    ];

    for (final crop in seedCrops) {
      await db.into(db.cropTable).insertOnConflictUpdate(crop);
    }
  }

  Crop _mapToEntity(CropTableData row) {
    return Crop(
      id: row.id,
      nameEn: row.nameEn,
      nameSi: row.nameSi,
      nameTa: row.nameTa,
      isSupported: row.isSupported == 1,
      iconAsset: row.iconAsset,
    );
  }
}
