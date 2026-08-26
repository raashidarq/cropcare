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
        id: 'apple',
        nameEn: 'Apple',
        nameSi: const Value('ඇපල්'),
        nameTa: const Value('ஆப்பிள்'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/apple.png'),
      ),
      CropTableCompanion.insert(
        id: 'blueberry',
        nameEn: 'Blueberry',
        nameSi: const Value('බ්ලූබෙරි'),
        nameTa: const Value('புளூபெர்ரி'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/blueberry.png'),
      ),
      CropTableCompanion.insert(
        id: 'cherry',
        nameEn: 'Cherry',
        nameSi: const Value('චෙරි'),
        nameTa: const Value('செர்ரி'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/cherry.png'),
      ),
      CropTableCompanion.insert(
        id: 'corn',
        nameEn: 'Corn (Maize)',
        nameSi: const Value('ඉරිඟු'),
        nameTa: const Value('சோளம்'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/corn.png'),
      ),
      CropTableCompanion.insert(
        id: 'grape',
        nameEn: 'Grape',
        nameSi: const Value('මිදි'),
        nameTa: const Value('திராட்சை'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/grape.png'),
      ),
      CropTableCompanion.insert(
        id: 'orange',
        nameEn: 'Orange (Citrus)',
        nameSi: const Value('දොඩම්'),
        nameTa: const Value('ஆரஞ்சு'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/orange.png'),
      ),
      CropTableCompanion.insert(
        id: 'peach',
        nameEn: 'Peach',
        nameSi: const Value('පීච්'),
        nameTa: const Value('பீச்'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/peach.png'),
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
        id: 'raspberry',
        nameEn: 'Raspberry',
        nameSi: const Value('රාස්ප්බෙරි'),
        nameTa: const Value('ராஸ்பெர்ரி'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/raspberry.png'),
      ),
      CropTableCompanion.insert(
        id: 'soybean',
        nameEn: 'Soybean',
        nameSi: const Value('සෝයා බෝංචි'),
        nameTa: const Value('சோயாபீன்'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/soybean.png'),
      ),
      CropTableCompanion.insert(
        id: 'squash',
        nameEn: 'Squash',
        nameSi: const Value('වට්ටක්කා'),
        nameTa: const Value('சுரைக்காய்'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/squash.png'),
      ),
      CropTableCompanion.insert(
        id: 'strawberry',
        nameEn: 'Strawberry',
        nameSi: const Value('ස්ට්‍රෝබෙරි'),
        nameTa: const Value('ஸ்ட்ராபெர்ரி'),
        isSupported: const Value(1),
        iconAsset: const Value('assets/icons/strawberry.png'),
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
