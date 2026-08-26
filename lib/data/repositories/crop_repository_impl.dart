import 'package:drift/drift.dart';

import '../../domain/entities/crop.dart';
import '../../domain/repositories/crop_repository.dart';
import '../local/database/app_database.dart';

class CropRepositoryImpl implements CropRepository {
  final AppDatabase db;

  CropRepositoryImpl(this.db);

  @override
  Future<List<Crop>> getSupportedCrops() async {
    await seedCrops();
    final crops = await (db.select(db.cropTable)
          ..where((t) => t.isSupported.equals(1)))
        .get();
    return crops.map(_mapToEntity).toList();
  }

  /// Seeds or updates all supported crop definitions.
  Future<void> seedCrops() async {
    final seedCrops = [
      CropTableCompanion.insert(
        id: 'corn',
        nameEn: 'Corn (Maize)',
        nameSi: const Value('ඉරිඟු'),
        nameTa: const Value('சோளம்'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/corn.png'),
      ),
      CropTableCompanion.insert(
        id: 'chili',
        nameEn: 'Chili / Bell Pepper',
        nameSi: const Value('මිරිස්'),
        nameTa: const Value('மிளகாய்'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/chili.png'),
      ),
      CropTableCompanion.insert(
        id: 'potato',
        nameEn: 'Potato',
        nameSi: const Value('අර්තාපල් (අල)'),
        nameTa: const Value('உருளைக்கிழங்கு'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/potato.png'),
      ),
      CropTableCompanion.insert(
        id: 'tomato',
        nameEn: 'Tomato',
        nameSi: const Value('තක්කාලි'),
        nameTa: const Value('தக்காளி'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/tomato.png'),
      ),
      CropTableCompanion.insert(
        id: 'paddy',
        nameEn: 'Paddy / Rice',
        nameSi: const Value('ගොයම්'),
        nameTa: const Value('நெல்'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/paddy.png'),
      ),
      CropTableCompanion.insert(
        id: 'cassava',
        nameEn: 'Cassava / Manioc',
        nameSi: const Value('මඤ්ඤොක්කා'),
        nameTa: const Value('மரவள்ளிக்கிழங்கு'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/cassava.png'),
      ),
      CropTableCompanion.insert(
        id: 'unknown',
        nameEn: 'Unknown Crop',
        nameSi: const Value('නොදන්නා බෝගය'),
        nameTa: const Value('தெரியாத பயிர்'),
        isSupported: const Value(0),
        iconAsset: const Value('assets/icons/unknown.png'),
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
