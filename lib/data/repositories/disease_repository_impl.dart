// lib/data/repositories/disease_repository_impl.dart
//
// Seeds the disease table with all 38 PlantVillage class names.
// The model output index matches the position in CLASS_NAMES below.
// Only diseases for crops that exist in the crop table are seeded
// (foreign-key constraint: disease.crop_id → crop.id).
//
// Crop IDs seeded by CropRepositoryImpl: 'tomato', 'chili', 'paddy'
// PlantVillage classes for Pepper/Bell map to 'chili' (closest match in our schema).
// All other crops (Apple, Blueberry, etc.) are NOT in our crop table —
// their diseases are intentionally omitted to satisfy the FK constraint.

import 'package:drift/drift.dart';

import '../local/database/app_database.dart';

class DiseaseRepositoryImpl {
  final AppDatabase db;

  DiseaseRepositoryImpl(this.db);

  /// Seeds disease rows if the table is empty or missing entries.
  /// Call this once after CropRepositoryImpl has seeded crops.
  Future<void> seedDiseasesIfEmpty() async {
    await _seedDiseases();
  }

  Future<void> _seedDiseases() async {
    // Each entry: (classIndex, id, cropId, nameEn, severityDefault)
    // classIndex == the index in the model's 38-class output.
    // id format: '<crop>_<disease_snake_case>' for readability.
    // Severity: 'low' | 'moderate' | 'high' | null (healthy rows).
    final diseases = <DiseaseTableCompanion>[
      // ── APPLE (class indices 0–3) ─────────────────────────────────
      DiseaseTableCompanion.insert(
        id: 'apple_scab',
        cropId: 'apple',
        nameEn: 'Apple Scab',
        severityDefault: const Value('moderate'),
      ),
      DiseaseTableCompanion.insert(
        id: 'apple_black_rot',
        cropId: 'apple',
        nameEn: 'Black Rot',
        severityDefault: const Value('high'),
      ),
      DiseaseTableCompanion.insert(
        id: 'apple_cedar_rust',
        cropId: 'apple',
        nameEn: 'Cedar Apple Rust',
        severityDefault: const Value('moderate'),
      ),
      DiseaseTableCompanion.insert(
        id: 'apple_healthy',
        cropId: 'apple',
        nameEn: 'Healthy',
        severityDefault: const Value(null),
      ),

      // ── BLUEBERRY (class index 4) ─────────────────────────────────
      DiseaseTableCompanion.insert(
        id: 'blueberry_healthy',
        cropId: 'blueberry',
        nameEn: 'Healthy',
        severityDefault: const Value(null),
      ),

      // ── CHERRY (class indices 5–6) ────────────────────────────────
      DiseaseTableCompanion.insert(
        id: 'cherry_powdery_mildew',
        cropId: 'cherry',
        nameEn: 'Powdery Mildew',
        severityDefault: const Value('moderate'),
      ),
      DiseaseTableCompanion.insert(
        id: 'cherry_healthy',
        cropId: 'cherry',
        nameEn: 'Healthy',
        severityDefault: const Value(null),
      ),

      // ── CORN / MAIZE (class indices 7–10) ─────────────────────────
      DiseaseTableCompanion.insert(
        id: 'corn_gray_leaf_spot',
        cropId: 'corn',
        nameEn: 'Cercospora / Gray Leaf Spot',
        severityDefault: const Value('moderate'),
      ),
      DiseaseTableCompanion.insert(
        id: 'corn_common_rust',
        cropId: 'corn',
        nameEn: 'Common Rust',
        severityDefault: const Value('moderate'),
      ),
      DiseaseTableCompanion.insert(
        id: 'corn_northern_leaf_blight',
        cropId: 'corn',
        nameEn: 'Northern Leaf Blight',
        severityDefault: const Value('high'),
      ),
      DiseaseTableCompanion.insert(
        id: 'corn_healthy',
        cropId: 'corn',
        nameEn: 'Healthy',
        severityDefault: const Value(null),
      ),

      // ── GRAPE (class indices 11–14) ───────────────────────────────
      DiseaseTableCompanion.insert(
        id: 'grape_black_rot',
        cropId: 'grape',
        nameEn: 'Black Rot',
        severityDefault: const Value('high'),
      ),
      DiseaseTableCompanion.insert(
        id: 'grape_black_measles',
        cropId: 'grape',
        nameEn: 'Esca (Black Measles)',
        severityDefault: const Value('high'),
      ),
      DiseaseTableCompanion.insert(
        id: 'grape_leaf_blight',
        cropId: 'grape',
        nameEn: 'Leaf Blight (Isariopsis)',
        severityDefault: const Value('moderate'),
      ),
      DiseaseTableCompanion.insert(
        id: 'grape_healthy',
        cropId: 'grape',
        nameEn: 'Healthy',
        severityDefault: const Value(null),
      ),

      // ── ORANGE (class index 15) ───────────────────────────────────
      DiseaseTableCompanion.insert(
        id: 'orange_citrus_greening',
        cropId: 'orange',
        nameEn: 'Huanglongbing (Citrus Greening)',
        severityDefault: const Value('high'),
      ),

      // ── PEACH (class indices 16–17) ───────────────────────────────
      DiseaseTableCompanion.insert(
        id: 'peach_bacterial_spot',
        cropId: 'peach',
        nameEn: 'Bacterial Spot',
        severityDefault: const Value('moderate'),
      ),
      DiseaseTableCompanion.insert(
        id: 'peach_healthy',
        cropId: 'peach',
        nameEn: 'Healthy',
        severityDefault: const Value(null),
      ),

      // ── CHILI / PEPPER BELL (class indices 18–19) ─────────────────
      DiseaseTableCompanion.insert(
        id: 'chili_bacterial_spot',
        cropId: 'chili',
        nameEn: 'Bacterial Spot',
        severityDefault: const Value('moderate'),
      ),
      DiseaseTableCompanion.insert(
        id: 'chili_healthy',
        cropId: 'chili',
        nameEn: 'Healthy',
        severityDefault: const Value(null),
      ),

      // ── POTATO (class indices 20–22) ──────────────────────────────
      DiseaseTableCompanion.insert(
        id: 'potato_early_blight',
        cropId: 'potato',
        nameEn: 'Early Blight',
        severityDefault: const Value('moderate'),
      ),
      DiseaseTableCompanion.insert(
        id: 'potato_late_blight',
        cropId: 'potato',
        nameEn: 'Late Blight',
        severityDefault: const Value('high'),
      ),
      DiseaseTableCompanion.insert(
        id: 'potato_healthy',
        cropId: 'potato',
        nameEn: 'Healthy',
        severityDefault: const Value(null),
      ),

      // ── RASPBERRY (class index 23) ────────────────────────────────
      DiseaseTableCompanion.insert(
        id: 'raspberry_healthy',
        cropId: 'raspberry',
        nameEn: 'Healthy',
        severityDefault: const Value(null),
      ),

      // ── SOYBEAN (class index 24) ──────────────────────────────────
      DiseaseTableCompanion.insert(
        id: 'soybean_healthy',
        cropId: 'soybean',
        nameEn: 'Healthy',
        severityDefault: const Value(null),
      ),

      // ── SQUASH (class index 25) ───────────────────────────────────
      DiseaseTableCompanion.insert(
        id: 'squash_powdery_mildew',
        cropId: 'squash',
        nameEn: 'Powdery Mildew',
        severityDefault: const Value('moderate'),
      ),

      // ── STRAWBERRY (class indices 26–27) ──────────────────────────
      DiseaseTableCompanion.insert(
        id: 'strawberry_leaf_scorch',
        cropId: 'strawberry',
        nameEn: 'Leaf Scorch',
        severityDefault: const Value('moderate'),
      ),
      DiseaseTableCompanion.insert(
        id: 'strawberry_healthy',
        cropId: 'strawberry',
        nameEn: 'Healthy',
        severityDefault: const Value(null),
      ),

      // ── TOMATO (class indices 28–37) ──────────────────────────────
      DiseaseTableCompanion.insert(
        id: 'tomato_bacterial_spot',
        cropId: 'tomato',
        nameEn: 'Bacterial Spot',
        severityDefault: const Value('moderate'),
      ),
      DiseaseTableCompanion.insert(
        id: 'tomato_early_blight',
        cropId: 'tomato',
        nameEn: 'Early Blight',
        severityDefault: const Value('moderate'),
      ),
      DiseaseTableCompanion.insert(
        id: 'tomato_late_blight',
        cropId: 'tomato',
        nameEn: 'Late Blight',
        severityDefault: const Value('high'),
      ),
      DiseaseTableCompanion.insert(
        id: 'tomato_leaf_mold',
        cropId: 'tomato',
        nameEn: 'Leaf Mold',
        severityDefault: const Value('moderate'),
      ),
      DiseaseTableCompanion.insert(
        id: 'tomato_septoria_leaf_spot',
        cropId: 'tomato',
        nameEn: 'Septoria Leaf Spot',
        severityDefault: const Value('moderate'),
      ),
      DiseaseTableCompanion.insert(
        id: 'tomato_spider_mites',
        cropId: 'tomato',
        nameEn: 'Spider Mites (Two-spotted)',
        severityDefault: const Value('moderate'),
      ),
      DiseaseTableCompanion.insert(
        id: 'tomato_target_spot',
        cropId: 'tomato',
        nameEn: 'Target Spot',
        severityDefault: const Value('moderate'),
      ),
      DiseaseTableCompanion.insert(
        id: 'tomato_yellow_leaf_curl_virus',
        cropId: 'tomato',
        nameEn: 'Yellow Leaf Curl Virus',
        severityDefault: const Value('high'),
      ),
      DiseaseTableCompanion.insert(
        id: 'tomato_mosaic_virus',
        cropId: 'tomato',
        nameEn: 'Mosaic Virus',
        severityDefault: const Value('high'),
      ),
      DiseaseTableCompanion.insert(
        id: 'tomato_healthy',
        cropId: 'tomato',
        nameEn: 'Healthy',
        severityDefault: const Value(null),
      ),

      // ── PADDY / RICE ──────────────────────────────────────────────
      DiseaseTableCompanion.insert(
        id: 'paddy_blast',
        cropId: 'paddy',
        nameEn: 'Rice Blast',
        severityDefault: const Value('high'),
      ),
      DiseaseTableCompanion.insert(
        id: 'paddy_healthy',
        cropId: 'paddy',
        nameEn: 'Healthy',
        severityDefault: const Value(null),
      ),

      // ── PADDY / RICE — added with the field model ─────────────
      DiseaseTableCompanion.insert(
        id: 'paddy_bacterial_leaf_blight',
        cropId: 'paddy',
        nameEn: 'Bacterial Leaf Blight',
        nameSi: const Value('බැක්ටීරියා පත්‍ර අංගමාරය'),
        nameTa: const Value('பாக்டீரியா இலைக் கருகல்'),
        severityDefault: const Value('high'),
      ),
      DiseaseTableCompanion.insert(
        id: 'paddy_bacterial_leaf_streak',
        cropId: 'paddy',
        nameEn: 'Bacterial Leaf Streak',
        nameSi: const Value('බැක්ටීරියා පත්‍ර ඉරි රෝගය'),
        nameTa: const Value('பாக்டீரியா இலைக் கோடு நோய்'),
        severityDefault: const Value('moderate'),
      ),
      DiseaseTableCompanion.insert(
        id: 'paddy_bacterial_panicle_blight',
        cropId: 'paddy',
        nameEn: 'Bacterial Panicle Blight',
        nameSi: const Value('බැක්ටීරියා කරල් අංගමාරය'),
        nameTa: const Value('பாக்டீரியா கதிர்க் கருகல்'),
        severityDefault: const Value('high'),
      ),
      DiseaseTableCompanion.insert(
        id: 'paddy_brown_spot',
        cropId: 'paddy',
        nameEn: 'Brown Spot',
        nameSi: const Value('දුඹුරු ලප රෝගය'),
        nameTa: const Value('பழுப்பு புள்ளி நோய்'),
        severityDefault: const Value('moderate'),
      ),
      DiseaseTableCompanion.insert(
        id: 'paddy_downy_mildew',
        cropId: 'paddy',
        nameEn: 'Downy Mildew',
        nameSi: const Value('රෝම පුස් රෝගය'),
        nameTa: const Value('பூஞ்சை நோய்'),
        severityDefault: const Value('moderate'),
      ),
      DiseaseTableCompanion.insert(
        id: 'paddy_tungro',
        cropId: 'paddy',
        nameEn: 'Tungro Virus',
        nameSi: const Value('ටංග්‍රෝ වයිරසය'),
        nameTa: const Value('துங்க்ரோ வைரஸ்'),
        severityDefault: const Value('high'),
      ),
      DiseaseTableCompanion.insert(
        id: 'paddy_dead_heart',
        cropId: 'paddy',
        nameEn: 'Stem Borer (Dead Heart)',
        nameSi: const Value('කඳ විදින දළඹුවා'),
        nameTa: const Value('தண்டு துளைப்பான்'),
        severityDefault: const Value('high'),
      ),
      DiseaseTableCompanion.insert(
        id: 'paddy_hispa',
        cropId: 'paddy',
        nameEn: 'Rice Hispa',
        nameSi: const Value('ගොයම් හිස්පා කුරුමිණියා'),
        nameTa: const Value('நெல் ஹிஸ்பா வண்டு'),
        severityDefault: const Value('moderate'),
      ),

      // ── CASSAVA / MANIOC ────────────────────────
      DiseaseTableCompanion.insert(
        id: 'cassava_bacterial_blight',
        cropId: 'cassava',
        nameEn: 'Cassava Bacterial Blight',
        nameSi: const Value('මඤ්ඤොක්කා බැක්ටීරියා අංගමාරය'),
        nameTa: const Value('மரவள்ளி பாக்டீரியா கருகல்'),
        severityDefault: const Value('high'),
      ),

      // ── CASSAVA / MANIOC ────────────────────────
      DiseaseTableCompanion.insert(
        id: 'cassava_brown_streak',
        cropId: 'cassava',
        nameEn: 'Cassava Brown Streak Disease',
        nameSi: const Value('මඤ්ඤොක්කා දුඹුරු ඉරි රෝගය'),
        nameTa: const Value('மரவள்ளி பழுப்பு கோடு நோய்'),
        severityDefault: const Value('high'),
      ),

      // ── CASSAVA / MANIOC ────────────────────────
      DiseaseTableCompanion.insert(
        id: 'cassava_green_mottle',
        cropId: 'cassava',
        nameEn: 'Cassava Green Mottle',
        nameSi: const Value('මඤ්ඤොක්කා කොළ පැල්ලම් රෝගය'),
        nameTa: const Value('மரவள்ளி பச்சை புள்ளி நோய்'),
        severityDefault: const Value('moderate'),
      ),

      // ── CASSAVA / MANIOC ────────────────────────
      DiseaseTableCompanion.insert(
        id: 'cassava_mosaic',
        cropId: 'cassava',
        nameEn: 'Cassava Mosaic Disease',
        nameSi: const Value('මඤ්ඤොක්කා මොසෙයික් රෝගය'),
        nameTa: const Value('மரவள்ளி மொசைக் நோய்'),
        severityDefault: const Value('high'),
      ),
    ];

    for (final disease in diseases) {
      await db.into(db.diseaseTable).insertOnConflictUpdate(disease);
    }

    await _seedTreatmentGuidelines();
  }

  Future<void> _seedTreatmentGuidelines() async {
    final guidelines = <TreatmentGuidelineTableCompanion>[
      // ── APPLE ──────────────────────────────────────────────────────
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_apple_scab',
        diseaseId: 'apple_scab',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Dark velvety olive-green spots on leaves and fruit that turn scabby.'),
        summarySi: const Value('පත්‍ර සහ ගෙඩි මත තද කොළ හෝ කළු පැහැති ලප ඇති වේ.'),
        summaryTa: const Value('இலைகள் மற்றும் பழங்களில் கருமையான பச்சை அல்லது கறுப்பு புள்ளிகள் தோன்றும்.'),
        whatToDoEn: const Value('Spray Captan or copper fungicide. Collect and burn all fallen infected leaves.'),
        whatToDoSi: const Value('කැප්ටාන් හෝ කොපර් දිලීර නාශකයක් ඉසින්න. බිම වැටුණු ආසාදිත කොළ එකතු කර පුළුස්සා දමන්න.'),
        whatToDoTa: const Value('கேப்டன் அல்லது காப்பர் பூஞ்சைக் கொல்லியைத் தெளிக்கவும். உதிர்ந்த இலைகளைச் சேகரித்து எரிக்கவும்.'),
        whatToAvoidEn: const Value('Do not water leaves from above. Keep leaves as dry as possible.'),
        whatToAvoidSi: const Value('උඩින් කොළවලට වතුර ඉසීමෙන් වළකින්න.'),
        whatToAvoidTa: const Value('இலைகள் மீது மேலிருந்து தண்ணீர் தெளிப்பதைத் தவிர்க்கவும்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_apple_black_rot',
        diseaseId: 'apple_black_rot',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Brown round leaf spots with dark edges and dark decaying fruit.'),
        summarySi: const Value('කොළ මත දුඹුරු ලප සහ ගෙඩි කළු වී කුණු වීම සිදු වේ.'),
        summaryTa: const Value('இலைகளில் பழுப்பு நிற புள்ளிகளும், பழங்கள் கறுத்து அழுகுவதும் ஏற்படும்.'),
        whatToDoEn: const Value('Cut off dead branches and rotting fruit. Spray Captan or Mancozeb fungicide.'),
        whatToDoSi: const Value('මියගිය අතු සහ කුණු වූ ගෙඩි කපා ඉවත් කරන්න. කැප්ටාන් හෝ මැන්කොසෙබ් ඉසින්න.'),
        whatToDoTa: const Value('காய்ந்த கிளைகளையும் அழுகிய பழங்களையும் வெட்டி அகற்றவும். மேன்கோசெப் தெளிக்கவும்.'),
        whatToAvoidEn: const Value('Do not leave rotten or dried fruits on trees or on the ground.'),
        whatToAvoidSi: const Value('කුණු වූ හෝ වියළුණු ගෙඩි ගසේ හෝ බිම දමා නොයන්න.'),
        whatToAvoidTa: const Value('அழுகிய பழங்களை மரத்திலோ தரையிலோ விட்டுவைக்காதீர்கள்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_apple_cedar_rust',
        diseaseId: 'apple_cedar_rust',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Bright yellow-orange spots on the upper side of leaves.'),
        summarySi: const Value('පත්‍රවල උඩ පැත්තේ දීප්තිමත් තැඹිලි-කහ පැහැති ලප ඇති වේ.'),
        summaryTa: const Value('இலைகளின் மேற்பகுதியில் பிரகாசமான மஞ்சள்-ஆரஞ்சு புள்ளிகள் தோன்றும்.'),
        whatToDoEn: const Value('Spray Myclobutanil or copper fungicide when young leaves first emerge.'),
        whatToDoSi: const Value('නව දළු එන විටම නිර්දේශිත කොපර් දිලීර නාශකයක් ඉසින්න.'),
        whatToDoTa: const Value('இளம் தளிர்கள் வரும்போதே காப்பர் பூஞ்சைக் கொல்லியைத் தெளிக்கவும்.'),
        whatToAvoidEn: const Value('Avoid planting apple trees close to wild juniper or cedar trees.'),
        whatToAvoidSi: const Value('වල් සීඩර් ගස් ආසන්නයේ ඇපල් පැළ සිටුවීමෙන් වළකින්න.'),
        whatToAvoidTa: const Value('ஜூனிபர் மரங்களுக்கு அருகில் நடவு செய்வதைத் தவிர்க்கவும்.'),
        recheckAfterDays: const Value(10),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),

      // ── CHERRY ─────────────────────────────────────────────────────
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_cherry_powdery_mildew',
        diseaseId: 'cherry_powdery_mildew',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('White powdery fungal coating on leaves causing young shoots to curl.'),
        summarySi: const Value('කොළ මත සුදු පිටි වැනි තට්ටුවක් බැඳී දළු හැකිලී යයි.'),
        summaryTa: const Value('இலைகளில் வெள்ளை மாவு போன்ற படலம் தோன்றி தளிர்கள் சுருங்கும்.'),
        whatToDoEn: const Value('Spray wettable sulfur or neem oil. Prune crowded branches so sunlight enters.'),
        whatToDoSi: const Value('සල්ෆර් හෝ කොහොඹ තෙල් ඉසින්න. හිරු එළිය සහ සුළං ලැබෙන සේ අතු කප්පාදු කරන්න.'),
        whatToDoTa: const Value('சல்பர் அல்லது வேப்ப எண்ணெய் தெளிக்கவும். சூரிய ஒளி படுமாறு கிளைகளைக் கத்தரிக்கவும்.'),
        whatToAvoidEn: const Value('Do not apply too much urea/nitrogen fertilizer.'),
        whatToAvoidSi: const Value('අධික ලෙස යූරියා (නයිට්‍රජන්) පොහොර යෙදීමෙන් වළකින්න.'),
        whatToAvoidTa: const Value('அதிகப்படியான யூரியா உரமிடுவதைத் தவிர்க்கவும்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),

      // ── CORN / MAIZE ───────────────────────────────────────────────
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_corn_gray_leaf_spot',
        diseaseId: 'corn_gray_leaf_spot',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Long rectangular grayish-brown spots running between leaf veins.'),
        summarySi: const Value('ඉරිඟු කොළ නාරටි අතර දිගටි අළු-දුඹුරු පැහැති ලප ඇති වේ.'),
        summaryTa: const Value('மக்காச்சோள இலை நரம்புகளுக்கு இடையே நீண்ட சாம்பல்-பழுப்பு புள்ளிகள் தோன்றும்.'),
        whatToDoEn: const Value('Spray fungicide if spots reach upper leaves before flowering. Rotate crops next season.'),
        whatToDoSi: const Value('මල් පිපීමට පෙර කොළවල ලප වැඩි නම් දිලීර නාශකයක් යොදන්න. ඊළඟ කන්නයේ වෙනත් බෝගයක් වගා කරන්න.'),
        whatToDoTa: const Value('பூ பூப்பதற்கு முன் இலைகளில் புள்ளிகள் அதிகமாக இருந்தால் பூஞ்சைக் கொல்லி தெளிக்கவும். அடுத்த பருவத்தில் பயிர் சுழற்சி செய்யவும்.'),
        whatToAvoidEn: const Value('Do not grow corn in the same soil season after season.'),
        whatToAvoidSi: const Value('එකම බිමේ දිගින් දිගටම ඉරිඟු වගා නොකරන්න.'),
        whatToAvoidTa: const Value('ஒரே நிலத்தில் தொடர்ந்து மக்காச்சோளம் பயிரிடாதீர்கள்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_corn_common_rust',
        diseaseId: 'corn_common_rust',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Small powdery reddish-brown rust blisters on both sides of leaves.'),
        summarySi: const Value('පත්‍ර දෙපැත්තේම කුඩා රතු-දුඹුරු මලකඩ පැහැති බිබිලි හටගනී.'),
        summaryTa: const Value('இலைகளின் இருபுறமும் சிறிய சிவப்பு-பழுப்பு துரு போன்ற கொப்புளங்கள் தோன்றும்.'),
        whatToDoEn: const Value('Plant rust-resistant corn seeds. Spray Mancozeb if blisters spread heavily.'),
        whatToDoSi: const Value('මලකඩ රෝගයට ඔරොත්තු දෙන බීජ වගා කරන්න. රෝගය පැතිරේ නම් මැන්කොසෙබ් ඉසින්න.'),
        whatToDoTa: const Value('துரு நோயை எதிர்க்கும் விதைகளை நடவும். நோய் பரவினால் மேன்கோசெப் தெளிக்கவும்.'),
        whatToAvoidEn: const Value('Avoid late planting when humid weather increases fungal spores.'),
        whatToAvoidSi: const Value('වැසි සහිත කාලවලදී ප්‍රමාද වී වගා කිරීමෙන් වළකින්න.'),
        whatToAvoidTa: const Value('அதிக ஈரப்பதம் உள்ள பருவத்தில் தாமதமாக நடவு செய்வதைத் தவிர்க்கவும்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_corn_northern_leaf_blight',
        diseaseId: 'corn_northern_leaf_blight',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Large cigar-shaped grayish-green or tan blighted patches on leaves.'),
        summarySi: const Value('පත්‍ර මත දිගටි සුරුට්ටු හැඩැති අළු-කොළ විශාල ලප ඇති වේ.'),
        summaryTa: const Value('இலைகளில் பெரிய சுருட்டு வடிவ சாம்பல்-பச்சை கருகல் புள்ளிகள் தோன்றும்.'),
        whatToDoEn: const Value('Apply recommended foliar fungicide at first sign. Plow and bury plant residues after harvest.'),
        whatToDoSi: const Value('රෝග ලක්ෂණ දුටු වහාම දිලීර නාශකයක් ඉසින්න. අස්වැන්න නෙලූ පසු ඉතිරි කොටස් පසට යට කරන්න.'),
        whatToDoTa: const Value('நோய் கண்டவுடன் பூஞ்சைக் கொல்லி தெளிக்கவும். அறுவடைக்குப் பின் எஞ்சிய பயிரை மண்ணில் உழுது புதைக்கவும்.'),
        whatToAvoidEn: const Value('Do not leave diseased corn stalks on the field surface.'),
        whatToAvoidSi: const Value('රෝගී ඉරිඟු දඬු ක්ෂේත්‍රයේ දමා නොයන්න.'),
        whatToAvoidTa: const Value('பாதிக்கப்பட்ட பயிர் எச்சங்களை நிலத்தில் அப்படியே விட்டுவிடாதீர்கள்.'),
        recheckAfterDays: const Value(5),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),

      // ── GRAPE ──────────────────────────────────────────────────────
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_grape_black_rot',
        diseaseId: 'grape_black_rot',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Brown leaf spots and small shriveled, blackened, dried-up grapes.'),
        summarySi: const Value('කොළ මත දුඹුරු ලප සහ මිදි ගෙඩි කළු වී වියළී හැකිලී යයි.'),
        summaryTa: const Value('இலைகளில் பழுப்பு புள்ளிகளும், திராட்சைப் பழங்கள் கறுத்து உலர்ந்து சுருங்குவதும் ஏற்படும்.'),
        whatToDoEn: const Value('Spray Mancozeb or Captan from early bud growth. Pick and burn dried shriveled berries.'),
        whatToDoSi: const Value('දළු එන අවධියේ සිට මැන්කොසෙබ් හෝ කැප්ටාන් ඉසින්න. වියළී ගිය ආසාදිත ගෙඩි කඩා විනාශ කරන්න.'),
        whatToDoTa: const Value('தளிர்கள் வரும்போதே மேன்கோசெப் தெளிக்கவும். காய்ந்த அழுகிய பழங்களை அகற்றி அழிக்கவும்.'),
        whatToAvoidEn: const Value('Do not leave shriveled berries hanging on vines.'),
        whatToAvoidSi: const Value('වියළුණු මිදි ගෙඩි වැල්වල ඉතිරි නොකරන්න.'),
        whatToAvoidTa: const Value('காய்ந்த திராட்சைப் பழங்களை கொடியில் விட்டுவைக்காதீர்கள்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_grape_black_measles',
        diseaseId: 'grape_black_measles',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Tiger-stripe yellow and brown patterns on leaves and spotted fruit.'),
        summarySi: const Value('පත්‍ර මත කොටියාගේ ඉරි වැනි රටා සහ ගෙඩි මත තද ලප හටගනී.'),
        summaryTa: const Value('இலைகளில் புலி வரி வடிவ மாற்றமும் பழங்களில் கரும்புள்ளிகளும் தோன்றும்.'),
        whatToDoEn: const Value('Paint pruning cuts with wound paste. Remove and burn dead diseased vines.'),
        whatToDoSi: const Value('අතු කපන ස්ථානවල ආරක්ෂිත ආලේපනයක් ගාන්න. මියගිය වැල් කපා පුළුස්සා දමන්න.'),
        whatToDoTa: const Value('கிளைகளை வெட்டிய இடங்களில் பூஞ்சைக் கொல்லி பசை தடவவும். காய்ந்த கொடிகளை அகற்றி எரிக்கவும்.'),
        whatToAvoidEn: const Value('Do not prune grapevines on wet rainy days.'),
        whatToAvoidSi: const Value('වැසි දිනවල අතු කප්පාදු නොකරන්න.'),
        whatToAvoidTa: const Value('மழை நாட்களில் கொடிகளை வெட்டுவதைத் தவிர்க்கவும்.'),
        recheckAfterDays: const Value(14),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_grape_leaf_blight',
        diseaseId: 'grape_leaf_blight',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Dark brown spots on leaves causing premature yellowing and leaf fall.'),
        summarySi: const Value('තද දුඹුරු ලප හටගෙන කොළ කහ වී ඉක්මනින් හැලී යයි.'),
        summaryTa: const Value('கரும் பழுப்பு புள்ளிகள் தோன்றி இலைகள் மஞ்சள் நிறமாகி உதிரும்.'),
        whatToDoEn: const Value('Spray copper fungicide. Thin out dense leaves so air and sunlight circulate.'),
        whatToDoSi: const Value('කොපර් දිලීර නාශකයක් ඉසින්න. හොඳින් හිරු එළිය සහ සුළං ලැබෙන සේ අතු තුනී කරන්න.'),
        whatToDoTa: const Value('காப்பர் பூஞ்சைக் கொல்லியைத் தெளிக்கவும். காற்று மற்றும் சூரிய ஒளி படுமாறு இலைகளைத் தணிக்கவும்.'),
        whatToAvoidEn: const Value('Do not allow dense, tangled, unpruned vine canopies.'),
        whatToAvoidSi: const Value('වැල් අධික ලෙස ළඟින් ළඟ පැටලී වැවීමට ඉඩ නොදෙන්න.'),
        whatToAvoidTa: const Value('அடர்த்தியாக கொடிகள் படர விடாதீர்கள்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),

      // ── ORANGE / CITRUS ────────────────────────────────────────────
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_orange_citrus_greening',
        diseaseId: 'orange_citrus_greening',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Uneven blotchy yellow patches on leaves and small lopsided bitter fruit.'),
        summarySi: const Value('පත්‍ර මත අසමාන කහ ලප ඇති වී ගෙඩි ඇද වී තිත්ත වේ.'),
        summaryTa: const Value('இலைகளில் ஒழுங்கற்ற மஞ்சள் புள்ளிகள் தோன்றி பழங்கள் சிறியதாக கசக்கும்.'),
        whatToDoEn: const Value('Control jumping plant lice (psyllids) with recommended spray. Buy only certified healthy plants.'),
        whatToDoSi: const Value('රෝගය පතුරුවන කෘමීන් (පැඟිරි මැක්කන්) මර්දනය කරන්න. සහතික කළ නිරෝගී පැළ පමණක් සිටුවන්න.'),
        whatToDoTa: const Value('நோயைப் பரப்பும் பூச்சிகளைக் கட்டுப்படுத்தவும். சான்றிதழ் பெற்ற ஆரோக்கியமான கன்றுகளை மட்டுமே நடவும்.'),
        whatToAvoidEn: const Value('Do not take grafts or cuttings from sick infected citrus trees.'),
        whatToAvoidSi: const Value('රෝගී ගස්වලින් අතු හෝ බද්ධ රිකිලි ලබා නොගන්න.'),
        whatToAvoidTa: const Value('பாதிக்கப்பட்ட மரங்களிலிருந்து ஒட்டுக் கட்டுகளை எடுக்காதீர்கள்.'),
        recheckAfterDays: const Value(14),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),

      // ── PEACH ──────────────────────────────────────────────────────
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_peach_bacterial_spot',
        diseaseId: 'peach_bacterial_spot',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Small dark spots on leaves that drop out, leaving tiny holes like shot-holes.'),
        summarySi: const Value('පත්‍ර මත කුඩා ලප හටගෙන ඒවා හැලී ගොස් සිදුරු ඇති වේ.'),
        summaryTa: const Value('இலைகளில் சிறிய புள்ளிகள் தோன்றி உதிர்ந்து துளைகளை உண்டாக்கும்.'),
        whatToDoEn: const Value('Spray copper spray before flowering. Keep trees healthy with balanced compost and water.'),
        whatToDoSi: const Value('මල් පිපීමට පෙර කොපර් දියර ඉසින්න. ගසට නිසි ජලය සහ පොහොර ලබා දෙන්න.'),
        whatToDoTa: const Value('பூக்கும் முன் காப்பர் தெளிக்கவும். தகுந்த உரம் மற்றும் தண்ணீர் வழங்கவும்.'),
        whatToAvoidEn: const Value('Avoid harsh summer pruning that causes weak succulent flushes.'),
        whatToAvoidSi: const Value('වියළි කාලවලදී අධික ලෙස අතු කප්පාදු කිරීමෙන් වළකින්න.'),
        whatToAvoidTa: const Value('கோடையில் அதிகப்படியான கிளைகளை வெட்டுவதைத் தவிர்க்கவும்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),

      // ── CHILI / BELL PEPPER ────────────────────────────────────────
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_chili_bacterial_spot',
        diseaseId: 'chili_bacterial_spot',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Small water-soaked dark spots on chili leaves turning brown and scabby.'),
        summarySi: const Value('මිරිස් කොළ මත කුඩා තෙත් ලප හටගෙන දුඹුරු පැහැ වී හැලී යයි.'),
        summaryTa: const Value('மிளகாய் இலைகளில் சிறிய நீர் புள்ளிகள் தோன்றி பழுப்பாகி உதிரும்.'),
        whatToDoEn: const Value('Spray copper hydroxide or Mancozeb. Plant disease-free certified seeds.'),
        whatToDoSi: const Value('කොපර් හයිඩ්‍රොක්සයිඩ් හෝ මැන්කොසෙබ් ඉසින්න. පිරිසිදු සහතික කළ බීජ භාවිත කරන්න.'),
        whatToDoTa: const Value('காப்பர் ஹைட்ராக்சைடு அல்லது மேன்கோசெப் தெளிக்கவும். நல்ல விதைகளைப் பயன்படுத்தவும்.'),
        whatToAvoidEn: const Value('Do not work in fields when leaves are wet. Avoid overhead watering.'),
        whatToAvoidSi: const Value('කොළ තෙත්ව ඇති විට ක්ෂේත්‍රයේ වැඩ නොකරන්න. උඩින් වතුර ඉසීමෙන් වළකින්න.'),
        whatToAvoidTa: const Value('இலைகள் ஈரமாக இருக்கும்போது வேலை செய்யாதீர்கள். மேலிருந்து தண்ணீர் ஊற்றாதீர்கள்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),

      // ── POTATO ─────────────────────────────────────────────────────
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_potato_early_blight',
        diseaseId: 'potato_early_blight',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Brown circular spots with target-like rings on older potato leaves.'),
        summarySi: const Value('පැරණි අර්තාපල් කොළ මත වළලු සහිත දුඹුරු ලප ඇති වේ.'),
        summaryTa: const Value('பழைய உருளைக்கிழங்கு இலைகளில் வளையங்களுடன் கூடிய பழுப்பு புள்ளிகள் தோன்றும்.'),
        whatToDoEn: const Value('Spray Mancozeb or Chlorothalonil. Keep soil consistently moist and fertilized.'),
        whatToDoSi: const Value('මැන්කොසෙබ් හෝ ක්ලෝරෝතැලොනිල් ඉසින්න. පසෙහි නියමිත තෙතමනය සහ පොහොර පවත්වා ගන්න.'),
        whatToDoTa: const Value('மேன்கோசெப் தெளிக்கவும். மண்ணில் சரியான ஈரப்பதத்தையும் உரத்தையும் பராமரிக்கவும்.'),
        whatToAvoidEn: const Value('Do not let plants dry out completely before heavy flooding.'),
        whatToAvoidSi: const Value('පැළ අධික ලෙස වියළීමට ඉඩ හැර එකවර අධිකව වතුර දැමීමෙන් වළකින්න.'),
        whatToAvoidTa: const Value('பயிர் காய்ந்த பிறகு திடீரென அதிக தண்ணீர் பாய்ச்சாதீர்கள்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_potato_late_blight',
        diseaseId: 'potato_late_blight',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Dark water-soaked rotting leaf patches with white mold underneath during damp weather.'),
        summarySi: const Value('පත්‍ර මත තෙත් අඳුරු ලප ඇති වී යටි පැත්තේ සුදු පුස් හටගනී.'),
        summaryTa: const Value('இலைகளில் நீர் ஊறின கரும்புள்ளிகள் தோன்றி அடியில் வெள்ளை பூஞ்சை உருவாகும்.'),
        whatToDoEn: const Value('Spray Metalaxyl or Mancozeb immediately. Cut and destroy infected stems before harvesting potatoes.'),
        whatToDoSi: const Value('මෙටලැක්සිල් හෝ මැන්කොසෙබ් වහාම ඉසින්න. අල ගැලවීමට පෙර ආසාදිත කොළ කපා විනාශ කරන්න.'),
        whatToDoTa: const Value('மெட்டலாக்ஸில் அல்லது மேன்கோசெப் உடனே தெளிக்கவும். கிழங்கு எடுப்பதற்கு முன் பாதிக்கப்பட்ட இலைகளை அழிக்கவும்.'),
        whatToAvoidEn: const Value('Never leave discarded rotten potatoes piled near fields.'),
        whatToAvoidSi: const Value('කුණු වූ ඉවතලන අල වගා බිම් අසල ගොඩගසා නොතබන්න.'),
        whatToAvoidTa: const Value('அழுகிய உருளைக்கிழங்குகளை வயல் அருகில் குவித்து வைக்காதீர்கள்.'),
        recheckAfterDays: const Value(5),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),

      // ── SQUASH ─────────────────────────────────────────────────────
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_squash_powdery_mildew',
        diseaseId: 'squash_powdery_mildew',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('White flour-like powdery coating on squash leaves and stems.'),
        summarySi: const Value('වට්ටක්කා කොළ සහ නැටි මත සුදු පිටි වැනි තට්ටුවක් ඇති වේ.'),
        summaryTa: const Value('சுரைக்காய் இலைகள் மற்றும் தண்டுகளில் வெள்ளை மாவு போன்ற படலம் தோன்றும்.'),
        whatToDoEn: const Value('Spray neem oil, baking soda solution, or sulfur. Give plants wide spacing.'),
        whatToDoSi: const Value('කොහොඹ තෙල්, බේකින් සෝඩා දියරය හෝ සල්ෆර් ඉසින්න. පැළ අතර ප්‍රමාණවත් පරතරයක් තබන්න.'),
        whatToDoTa: const Value('வேப்ப எண்ணெய், சமையல் சோடா கரைசல் அல்லது சல்பர் தெளிக்கவும். செடிகளுக்கு இடையே போதிய இடைவெளி விடவும்.'),
        whatToAvoidEn: const Value('Avoid crowded planting and shaded humid areas.'),
        whatToAvoidSi: const Value('ළඟින් ළඟ පැළ සිටුවීමෙන් සහ හිරු එළිය නොවැටෙන තැන්වල වගා කිරීමෙන් වළකින්න.'),
        whatToAvoidTa: const Value('நிழலான மற்றும் காற்று வசதி இல்லாத இடங்களில் நெருக்கமாக நடாதீர்கள்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),

      // ── STRAWBERRY ─────────────────────────────────────────────────
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_strawberry_leaf_scorch',
        diseaseId: 'strawberry_leaf_scorch',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Small purplish-brown spots on strawberry leaves that dry up and turn brown.'),
        summarySi: const Value('ස්ට්‍රෝබෙරි කොළ මත දම්-දුඹුරු පැහැති කුඩා ලප හටගෙන කොළ පිලිස්සී යයි.'),
        summaryTa: const Value('இலைகளில் சிறிய ஊதா-பழுப்பு புள்ளிகள் தோன்றி இலைகள் கருகும்.'),
        whatToDoEn: const Value('Cut and remove old spotted leaves after picking berries. Spray copper fungicide.'),
        whatToDoSi: const Value('අස්වැන්න නෙලූ පසු රෝගී පැරණි කොළ කපා ඉවත් කරන්න. කොපර් දිලීර නාශක ඉසින්න.'),
        whatToDoTa: const Value('அறுவடைக்குப் பின் பழைய பாதிக்கப்பட்ட இலைகளை வெட்டவும். காப்பர் பூஞ்சைக் கொல்லி தெளிக்கவும்.'),
        whatToAvoidEn: const Value('Avoid poorly drained waterlogged soil.'),
        whatToAvoidSi: const Value('ජලය බැස නොයන මඩ සහිත පසෙහි සිටුවීමෙන් වළකින්න.'),
        whatToAvoidTa: const Value('தண்ணீர் தேங்கும் நிலத்தில் நடவு செய்வதைத் தவிர்க்கவும்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),

      // ── TOMATO ─────────────────────────────────────────────────────
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_tomato_bacterial_spot',
        diseaseId: 'tomato_bacterial_spot',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Small brown spots with yellow borders on tomato leaves and fruit.'),
        summarySi: const Value('තක්කාලි කොළ මත කහ මායිමක් සහිත කුඩා දුඹුරු ලප ඇති වේ.'),
        summaryTa: const Value('தக்காளி இலைகளில் மஞ்சள் வளையத்துடன் கூடிய சிறிய பழுப்பு புள்ளிகள் தோன்றும்.'),
        whatToDoEn: const Value('Spray copper hydroxide mixed with Mancozeb. Use clean certified seeds.'),
        whatToDoSi: const Value('කොපර් හයිඩ්‍රොක්සයිඩ් සහ මැන්කොසෙබ් මිශ්‍ර කර ඉසින්න. පිරිසිදු බීජ භාවිත කරන්න.'),
        whatToDoTa: const Value('காப்பர் ஹைட்ராக்சைடு மற்றும் மேன்கோசெப் கலந்து தெளிக்கவும். தரமான விதைகளைப் பயன்படுத்தவும்.'),
        whatToAvoidEn: const Value('Do not handle plants or weed when foliage is wet.'),
        whatToAvoidSi: const Value('පත්‍ර තෙත්ව ඇති විට පැළ ඇල්ලීමෙන් හෝ වල් නෙලීමෙන් වළකින්න.'),
        whatToAvoidTa: const Value('இலைகள் ஈரமாக இருக்கும்போது செடிகளைத் தொடவோ களையெடுக்கவோ வேண்டாம்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_tomato_early_blight',
        diseaseId: 'tomato_early_blight',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Dark spots with target-like concentric rings on lower tomato leaves.'),
        summarySi: const Value('පහළ තක්කාලි කොළ මත වළලු සහිත අඳුරු දුඹුරු ලප ඇති වේ.'),
        summaryTa: const Value('கீழ் தக்காளி இலைகளில் வளையங்களுடன் கூடிய கரும்புள்ளிகள் தோன்றும்.'),
        whatToDoEn: const Value('Cut off lower infected leaves. Spray copper fungicide or Mancozeb. Stake plants off the ground.'),
        whatToDoSi: const Value('පහළ ආසාදිත කොළ කපා ඉවත් කරන්න. කොපර් දිලීර නාශකයක් ඉසින්න. පැළ ආධාරකවලට බඳින්න.'),
        whatToDoTa: const Value('பாதிக்கப்பட்ட கீழ் இலைகளை வெட்டி அகற்றவும். காப்பர் பூஞ்சைக் கொல்லி தெளிக்கவும். செடிகளைத் தாங்கி கட்டவும்.'),
        whatToAvoidEn: const Value('Do not water leaves from above. Do not leave pruned leaves on soil.'),
        whatToAvoidSi: const Value('උඩින් කොළවලට වතුර නොදමන්න. කපා දැමූ කොළ බිම දමා නොයන්න.'),
        whatToAvoidTa: const Value('மேலிருந்து தண்ணீர் தெளிக்காதீர்கள். வெட்டிய இலைகளை நிலத்தில் விடாதீர்கள்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_tomato_late_blight',
        diseaseId: 'tomato_late_blight',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Rapidly spreading wet dark brown patches on leaves and stems with white fuzz underneath.'),
        summarySi: const Value('පත්‍ර සහ කඳන් මත වේගයෙන් පැතිරෙන තෙත් කළු ලප ඇති වී සුදු පුස් හටගනී.'),
        summaryTa: const Value('இலைகள் மற்றும் தண்டுகளில் வேகமாகப் பரவும் கரும்புள்ளிகளும் அடியில் வெள்ளை பூஞ்சையும் தோன்றும்.'),
        whatToDoEn: const Value('Spray Mancozeb or systemic copper fungicide right away. Pull up and burn heavily infected plants.'),
        whatToDoSi: const Value('මැන්කොසෙබ් හෝ කොපර් දිලීර නාශකයක් වහාම ඉසින්න. දැඩි ලෙස හානි වූ පැළ ගලවා පුළුස්සා දමන්න.'),
        whatToDoTa: const Value('மேன்கோசெப் அல்லது காப்பர் பூஞ்சைக் கொல்லியை உடனே தெளிக்கவும். அதிகம் பாதிக்கப்பட்ட செடிகளைப் பிடுங்கி அழிக்கவும்.'),
        whatToAvoidEn: const Value('Do not touch healthy plants after touching wet sick plants.'),
        whatToAvoidSi: const Value('තෙතමනය ඇති විට පැළ ඇල්ලීමෙන් වළකින්න.'),
        whatToAvoidTa: const Value('ஈரமாக இருக்கும்போது செடிகளைத் தொடாதீர்கள்.'),
        recheckAfterDays: const Value(5),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_tomato_leaf_mold',
        diseaseId: 'tomato_leaf_mold',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Pale yellow spots on the upper leaf and olive-green velvety mold underneath.'),
        summarySi: const Value('කොළවල උඩ පැත්තේ කහ ලප සහ යටි පැත්තේ ඔලිව් කොළ පැහැති වෙල්වට් පුස් හටගනී.'),
        summaryTa: const Value('இலைகளின் மேற்பகுதியில் மஞ்சள் புள்ளிகளும், அடியில் பச்சை நிற பூஞ்சையும் தோன்றும்.'),
        whatToDoEn: const Value('Open greenhouse sides to increase airflow and lower humidity. Spray copper fungicide.'),
        whatToDoSi: const Value('හොඳින් සුළං ලැබෙන සේ වාතාශ්‍රය වැඩි කරන්න. කොපර් දිලීර නාශකයක් ඉසින්න.'),
        whatToDoTa: const Value('நல்ல காற்று வசதியை ஏற்படுத்தி ஈரப்பதத்தைக் குறைக்கவும். காப்பர் பூஞ்சைக் கொல்லி தெளிக்கவும்.'),
        whatToAvoidEn: const Value('Avoid high humidity and stagnant air in greenhouses or poly-tunnels.'),
        whatToAvoidSi: const Value('සංවෘත වගාගාර තුළ අධික තෙතමනය සහ වාතාශ්‍රය අවහිර වීමට ඉඩ නොදෙන්න.'),
        whatToAvoidTa: const Value('அதிக ஈரப்பதம் மற்றும் காற்று தேங்குவதைத் தவிர்க்கவும்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_tomato_septoria_leaf_spot',
        diseaseId: 'tomato_septoria_leaf_spot',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Many small round spots with dark edges and grayish centers on lower leaves.'),
        summarySi: const Value('පහළ කොළ මත අළු මැදක් සහිත කුඩා වටකුරු ලප රාශියක් ඇති වේ.'),
        summaryTa: const Value('கீழ் இலைகளில் சாம்பல் நிற மையத்துடன் கூடிய சிறிய வட்ட புள்ளிகள் தோன்றும்.'),
        whatToDoEn: const Value('Snip off diseased bottom leaves. Place straw mulch under plants. Spray copper or Chlorothalonil.'),
        whatToDoSi: const Value('පහළ රෝගී කොළ කපා ඉවත් කරන්න. ශාක පාමුලට පිදුරු හෝ වසුන් යොදන්න. කොපර් ඉසින්න.'),
        whatToDoTa: const Value('கீழ் இலைகளை வெட்டி அகற்றவும். செடியின் அடியில் வைக்கோல் பரப்பவும். காப்பர் தெளிக்கவும்.'),
        whatToAvoidEn: const Value('Do not splash soil onto leaves when watering.'),
        whatToAvoidSi: const Value('වතුර දමන විට පස් වතුර කොළ මතට විසිවීමට ඉඩ නොදෙන්න.'),
        whatToAvoidTa: const Value('தண்ணீர் பாய்ச்சும்போது மண் இலைகளில் தெறிக்காமல் பார்த்துக்கொள்ளவும்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_tomato_spider_mites',
        diseaseId: 'tomato_spider_mites',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Fine yellow speckling, tiny spider webs, and bronzing on leaf undersides.'),
        summarySi: const Value('කොළ මත කුඩා කහ තිත්, සියුම් මකුළු දැල් සහ කොළ දුඹුරු පැහැ වීම සිදු වේ.'),
        summaryTa: const Value('இலைகளில் சிறிய மஞ்சள் புள்ளிகள், மெல்லிய வலைகள் மற்றும் இலைகள் பழுப்பாதல் தோன்றும்.'),
        whatToDoEn: const Value('Spray soapy water, neem oil, or sulfur under leaves. Keep soil well-watered.'),
        whatToDoSi: const Value('සබන් වතුර, කොහොඹ තෙල් හෝ කීඩෑ නාශක පත්‍රවල යටි පැත්තට හොඳින් ඉසින්න.'),
        whatToDoTa: const Value('சோப்பு நீர், வேப்ப எண்ணெய் அல்லது சல்பர் கரைசலை இலைகளின் அடியில் தெளிக்கவும்.'),
        whatToAvoidEn: const Value('Avoid dusty dry conditions and harsh chemical sprays that kill good predatory bugs.'),
        whatToAvoidSi: const Value('දූවිලි සහිත වියළි පරිසරයක් ඇති වීමට ඉඩ නොදෙන්න. හිතකර කෘමීන් විනාශ කරන කෘමිනාශක භාවිත නොකරන්න.'),
        whatToAvoidTa: const Value('அதிக தூசியான சூழலைத் தவிர்க்கவும். நன்மை செய்யும் பூச்சிகளைக் கொல்லும் மருந்துகளைத் தவிர்க்கவும்.'),
        recheckAfterDays: const Value(5),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_tomato_target_spot',
        diseaseId: 'tomato_target_spot',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Round brown spots with faint target-like rings and yellow halos on leaves.'),
        summarySi: const Value('කොළ මත කහ මායිමක් සහිත වටකුරු දුඹුරු ලප ඇති වේ.'),
        summaryTa: const Value('இலைகளில் மஞ்சள் வளையத்துடன் கூடிய வட்ட வடிவ பழுப்பு புள்ளிகள் தோன்றும்.'),
        whatToDoEn: const Value('Tie plants to stakes and prune crowded leaves to let air flow. Spray copper or Mancozeb.'),
        whatToDoSi: const Value('පැළ ආධාරකවලට බැඳ අතු තුනී කරන්න. කොපර් හෝ මැන්කොසෙබ් ඉසින්න.'),
        whatToDoTa: const Value('செடிகளைத் தாங்கிகளில் கட்டி இலைகளைத் தணிக்கவும். காப்பர் அல்லது மேன்கோசெப் தெளிக்கவும்.'),
        whatToAvoidEn: const Value('Do not plant in low soggy areas where water stays pooled.'),
        whatToAvoidSi: const Value('ජලය රැඳෙන පහත් මඩ බිම්වල සිටුවීමෙන් වළකින්න.'),
        whatToAvoidTa: const Value('தண்ணீர் தேங்கும் தாழ்வான பகுதிகளில் நடாதீர்கள்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_tomato_yellow_leaf_curl_virus',
        diseaseId: 'tomato_yellow_leaf_curl_virus',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Leaves curl upward, turn yellow around edges, and plants become stunted with dropped flowers.'),
        summarySi: const Value('කොළ උඩට හැකිලී කහ පැහැ වී පැළ කුරු වේ. මල් හැලී යයි.'),
        summaryTa: const Value('இலைகள் மேல்நோக்கி சுருங்கி மஞ்சள் நிறமாகி செடிகள் குட்டையாகும். பூக்கள் உதிரும்.'),
        whatToDoEn: const Value('Hang yellow sticky traps to catch whiteflies. Pull up and bag heavily sick plants immediately.'),
        whatToDoSi: const Value('සුදු මැස්සන් අල්ලන කහ ඇලෙන උගුල් එල්ලන්න. දැඩි ලෙස රෝගී පැළ ගලවා උරයක දමා විනාශ කරන්න.'),
        whatToDoTa: const Value('வெள்ளை ஈக்களைப் பிடிக்க மஞ்சள் ஒட்டும் பொறிகளைப் பயன்படுத்தவும். பாதிக்கப்பட்ட செடிகளை உடனே அகற்றவும்.'),
        whatToAvoidEn: const Value('Do not allow weeds or old tomato plants to grow near the field.'),
        whatToAvoidSi: const Value('ක්ෂේත්‍රය අවට වල් පැළ හෝ පරණ තක්කාලි පැළ තිබීමට ඉඩ නොදෙන්න.'),
        whatToAvoidTa: const Value('வயல் அருகில் களைகள் மற்றும் பழைய தக்காளி செடிகளை வளர விடாதீர்கள்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_tomato_mosaic_virus',
        diseaseId: 'tomato_mosaic_virus',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Light and dark green mottled patchwork on leaves with leaf distortion.'),
        summarySi: const Value('පත්‍ර මත ලා කොළ සහ තද කොළ පැහැති විසිතුරු පැල්ලම් රටා ඇති වේ.'),
        summaryTa: const Value('இலைகளில் வெளிர் மற்றும் அடர் பச்சை நிற திட்டுகள் தோன்றி இலைகள் சுருங்கும்.'),
        whatToDoEn: const Value('Wash and disinfect pruning tools with soap or bleach. Pull up and burn infected plants.'),
        whatToDoSi: const Value('කප්පාදු කතුරු සබන් හෝ විෂබීජ නාශක දියරයෙන් සෝදන්න. ආසාදිත පැළ ගලවා පුළුස්සා දමන්න.'),
        whatToDoTa: const Value('கத்தரிக்கும் கருவிகளை சோப்பு நீரால் கழுவவும். பாதிக்கப்பட்ட செடிகளைப் பிடுங்கி எரிக்கவும்.'),
        whatToAvoidEn: const Value('Do not smoke or use tobacco products near tomato plants (virus spreads via hands).'),
        whatToAvoidSi: const Value('තක්කාලි පැළ අසල දුම්කොළ භාවිත නොකරන්න (අත් මගින් වෛරසය බෝ වේ).'),
        whatToAvoidTa: const Value('தக்காளி செடிகள் அருகில் புகையிலைப் பொருட்களைப் பயன்படுத்தாதீர்கள் (கைகள் மூலம் வைரஸ் பரவும்).'),
        recheckAfterDays: const Value(10),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),

      // ── PADDY / RICE ───────────────────────────────────────────────
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_paddy_blast',
        diseaseId: 'paddy_blast',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Diamond or eye-shaped spots with gray centers and brown borders on paddy leaves.'),
        summarySi: const Value('ගොයම් කොළ මත අළු මැදක් සහ දුඹුරු මායිමක් සහිත ඇසක හැඩැති ලප ඇති වේ.'),
        summaryTa: const Value('நெல் இலைகளில் சாம்பல் நிற மையத்துடன் கூடிய கண் வடிவ புள்ளிகள் தோன்றும்.'),
        whatToDoEn: const Value('Spray Tricyclazole or Isoprothiolane at first sign. Keep 2 to 3 inches of standing water in fields.'),
        whatToDoSi: const Value('රෝග ලක්ෂණ දුටු වහාම ට්‍රයිසයික්ලසෝල් ඉසින්න. ලියැදිවල නිසි ජල මට්ටම පවත්වා ගන්න.'),
        whatToDoTa: const Value('நோய் கண்டவுடன் ட்ரைசைக்ளசோல் தெளிக்கவும். வயலில் தகுந்த நீர் மட்டத்தைப் பராமரிக்கவும்.'),
        whatToAvoidEn: const Value('Do not overuse urea (nitrogen) fertilizer when weather is cool and wet.'),
        whatToAvoidSi: const Value('අධික ලෙස යූරියා (නයිට්‍රජන්) පොහොර යෙදීමෙන් වළකින්න.'),
        whatToAvoidTa: const Value('அதிகப்படியான யூரியா உரமிடுவதைத் தவிர்க்கவும்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),

      // ── RICE AND CASSAVA — sourced, see ml/CONTENT_SOURCES.md ───
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_paddy_bacterial_leaf_blight',
        diseaseId: 'paddy_bacterial_leaf_blight',
        guidelineVersion: 'tg-2026.02',
        summaryEn: const Value('Leaves turn yellow then straw-coloured and dry from the tip down. Young plants can wilt and die.'),
        summarySi: const Value('පත්‍ර කහ පැහැ වී පසුව වියළී යයි. ළපටි පැළ මැරී යා හැක.'),
        summaryTa: const Value('இலைகள் மஞ்சளாகி பின் காய்ந்து போகும். இளம் நாற்றுகள் வாடி இறக்கலாம்.'),
        whatToDoEn: const Value('Drain the field for a few days. Remove weeds from the bunds and plough in old stubble. Use balanced fertiliser. Plant a resistant variety next season.'),
        whatToDoSi: const Value('ලියැද්ද දින කිහිපයක් වේලෙන්න හරින්න. නියරවල වල් නෙළා පැරණි කරල් සී සාන්න. සමතුලිත පොහොර යොදන්න. ඊළඟ කන්නයේ ප්‍රතිරෝධී ප්‍රභේදයක් වවන්න.'),
        whatToDoTa: const Value('வயலை சில நாட்கள் வடிய விடவும். வரப்புகளில் உள்ள களைகளை அகற்றவும். சமச்சீர் உரமிடவும். அடுத்த பருவத்தில் எதிர்ப்புத் திறன் உள்ள ரகத்தை நடவும்.'),
        whatToAvoidEn: const Value('Do not add extra urea. Do not leave infected stubble or ratoons standing.'),
        whatToAvoidSi: const Value('අමතර යූරියා යෙදීමෙන් වළකින්න. ආසාදිත කරල් ලියැද්දේ තබා නොගන්න.'),
        whatToAvoidTa: const Value('கூடுதல் யூரியா இடாதீர்கள். பாதிக்கப்பட்ட தாள்களை வயலில் விடாதீர்கள்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-02-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_paddy_bacterial_leaf_streak',
        diseaseId: 'paddy_bacterial_leaf_streak',
        guidelineVersion: 'tg-2026.02',
        summaryEn: const Value('Narrow water-soaked streaks between the leaf veins turn yellow-brown. Badly hit leaves dry early.'),
        summarySi: const Value('පත්‍ර නාරටි අතර පටු තෙත් ඉරි කහ-දුඹුරු පැහැයට හැරේ. දැඩි ලෙස වැළඳුණු පත්‍ර ඉක්මනින් වියළේ.'),
        summaryTa: const Value('இலை நரம்புகளுக்கு இடையே நீர் ஊறிய கோடுகள் மஞ்சள்-பழுப்பாக மாறும். மோசமாக பாதிக்கப்பட்ட இலைகள் சீக்கிரம் காய்ந்துவிடும்.'),
        whatToDoEn: const Value('Use clean seed from a healthy field next sowing. Drain the field for a few days. Remove weed hosts from the bunds. Use balanced fertiliser.'),
        whatToDoSi: const Value('ඊළඟ වපුරන විට නිරෝගී ලියැද්දකින් බීජ ගන්න. ලියැද්ද දින කිහිපයක් වේලෙන්න හරින්න. නියරවල වල් නෙළන්න. සමතුලිත පොහොර යොදන්න.'),
        whatToDoTa: const Value('அடுத்த விதைப்பில் ஆரோக்கியமான வயலிலிருந்து விதை எடுக்கவும். வயலை சில நாட்கள் வடிய விடவும். வரப்பு களைகளை அகற்றவும். சமச்சீர் உரமிடவும்.'),
        whatToAvoidEn: const Value('Do not add extra urea. Do not walk through the crop while the leaves are wet.'),
        whatToAvoidSi: const Value('අමතර යූරියා යෙදීමෙන් වළකින්න. පත්‍ර තෙත්ව ඇති විට ගොයම් අතරින් නොයන්න.'),
        whatToAvoidTa: const Value('கூடுதல் யூரியா இடாதீர்கள். இலைகள் ஈரமாக இருக்கும்போது பயிருக்குள் நடக்காதீர்கள்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-02-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_paddy_bacterial_panicle_blight',
        diseaseId: 'paddy_bacterial_panicle_blight',
        guidelineVersion: 'tg-2026.02',
        summaryEn: const Value('Grains do not fill and panicles stay upright and pale. It is worst in very hot weather.'),
        summarySi: const Value('කරල් පිරෙන්නේ නැත, සුදුමැලි වී කෙළින් සිටී. දැඩි උණුසුම් කාලගුණයේ වැඩි වේ.'),
        summaryTa: const Value('தானியங்கள் நிரம்பாமல் கதிர்கள் வெளிறி நிமிர்ந்து நிற்கும். மிக வெப்பமான காலநிலையில் அதிகமாகும்.'),
        whatToDoEn: const Value('Use pathogen-free seed next season. Plant a resistant variety if one is available. Space the plants so air moves through the crop.'),
        whatToDoSi: const Value('ඊළඟ කන්නයේ රෝග රහිත බීජ භාවිත කරන්න. ලබා ගත හැකි නම් ප්‍රතිරෝධී ප්‍රභේදයක් වවන්න. වාතය ගමන් කරන ලෙස පැළ අතර ඉඩ තබන්න.'),
        whatToDoTa: const Value('அடுத்த பருவத்தில் நோயற்ற விதையைப் பயன்படுத்தவும். கிடைத்தால் எதிர்ப்புத் திறன் உள்ள ரகத்தை நடவும். காற்று செல்ல இடைவெளி விட்டு நடவும்.'),
        whatToAvoidEn: const Value('Do not sow thickly. Do not add extra nitrogen when the crop is booting.'),
        whatToAvoidSi: const Value('ඝනව වපුරන්න එපා. කරල් හැදෙන අවස්ථාවේ අමතර නයිට්‍රජන් නොයොදන්න.'),
        whatToAvoidTa: const Value('அடர்த்தியாக விதைக்காதீர்கள். கதிர் வரும் நேரத்தில் கூடுதல் நைட்ரஜன் இடாதீர்கள்.'),
        recheckAfterDays: const Value(10),
        publishedAt: const Value('2026-02-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_paddy_brown_spot',
        diseaseId: 'paddy_brown_spot',
        guidelineVersion: 'tg-2026.02',
        summaryEn: const Value('Small brown oval spots cover the leaves. It is usually a sign of poor or hungry soil.'),
        summarySi: const Value('පත්‍ර මත කුඩා දුඹුරු ලප පැතිරේ. මෙය බොහෝ විට දුර්වල පසක ලකුණකි.'),
        summaryTa: const Value('இலைகளில் சிறிய பழுப்பு நிற புள்ளிகள் பரவும். இது பொதுவாக மண் வளம் குறைவின் அறிகுறி.'),
        whatToDoEn: const Value('Correct the soil first with compost and balanced fertiliser. Keep the water level steady. Treat the seed with a fungicide before next sowing.'),
        whatToDoSi: const Value('පළමුව කොම්පෝස්ට් සහ සමතුලිත පොහොර යොදා පස නිවැරදි කරන්න. ජල මට්ටම ස්ථිරව තබා ගන්න. ඊළඟ වපුරන්නට පෙර බීජ දිලීර නාශකයකින් පිරිපහදු කරන්න.'),
        whatToDoTa: const Value('முதலில் மட்கு உரமும் சமச்சீர் உரமும் இட்டு மண்ணை சரிசெய்யவும். நீர் மட்டத்தை நிலையாக வைக்கவும். அடுத்த விதைப்புக்கு முன் விதையை பூஞ்சைக் கொல்லியில் நனைக்கவும்.'),
        whatToAvoidEn: const Value('Do not let the field go short of water. Do not sow untreated seed from an affected crop.'),
        whatToAvoidSi: const Value('ලියැද්ද ජලය නොමැතිව වියළෙන්නට ඉඩ නොදෙන්න. ආසාදිත ගොයමින් පිරිපහදු නොකළ බීජ නොවපුරන්න.'),
        whatToAvoidTa: const Value('வயலில் நீர் பற்றாக்குறை ஏற்பட விடாதீர்கள். பாதிக்கப்பட்ட பயிரின் விதையை சுத்திகரிக்காமல் விதைக்காதீர்கள்.'),
        recheckAfterDays: const Value(10),
        publishedAt: const Value('2026-02-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_paddy_downy_mildew',
        diseaseId: 'paddy_downy_mildew',
        guidelineVersion: 'tg-2026.02',
        summaryEn: const Value('Seedlings are stunted and twisted with pale yellow patches. It shows up where water sits.'),
        summarySi: const Value('පැළ කුරු වී ඇඹරී පවතී, සුදුමැලි කහ පැල්ලම් සහිතව. ජලය රැඳෙන තැන්වල මතු වේ.'),
        summaryTa: const Value('நாற்றுகள் வளராமல் திரிந்து வெளிறிய மஞ்சள் திட்டுகளுடன் இருக்கும். நீர் தேங்கும் இடங்களில் தோன்றும்.'),
        whatToDoEn: const Value('Drain the low, waterlogged patches. Clear the field channels so water moves away. Remove and destroy badly affected seedlings.'),
        whatToDoSi: const Value('ජලය රැඳී ඇති පහත් තැන් වේලෙන්න හරින්න. ජලය බැස යන ලෙස ලියැදි ඇළ පිරිසිදු කරන්න. දැඩි ලෙස වැළඳුණු පැළ ඉවත් කර විනාශ කරන්න.'),
        whatToDoTa: const Value('நீர் தேங்கிய தாழ்வான பகுதிகளை வடிய விடவும். நீர் வெளியேற வாய்க்கால்களை சுத்தம் செய்யவும். மோசமாக பாதிக்கப்பட்ட நாற்றுகளை அகற்றி அழிக்கவும்.'),
        whatToAvoidEn: const Value('Do not raise seedbeds on waterlogged ground.'),
        whatToAvoidSi: const Value('ජලය රැඳෙන බිමක බීජ තවාන් නොසාදන්න.'),
        whatToAvoidTa: const Value('நீர் தேங்கும் நிலத்தில் நாற்றங்கால் அமைக்காதீர்கள்.'),
        recheckAfterDays: const Value(10),
        publishedAt: const Value('2026-02-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_paddy_tungro',
        diseaseId: 'paddy_tungro',
        guidelineVersion: 'tg-2026.02',
        summaryEn: const Value('Plants stay short with orange-yellow leaves. A leafhopper carries it from plant to plant.'),
        summarySi: const Value('පැළ කුරු වී තැඹිලි-කහ පත්‍ර සහිතව පවතී. පත්‍ර පනින්නා එය පැළෙන් පැළට ගෙන යයි.'),
        summaryTa: const Value('செடிகள் குட்டையாக ஆரஞ்சு-மஞ்சள் இலைகளுடன் இருக்கும். இலைத்தத்துப்பூச்சி இதை பரப்புகிறது.'),
        whatToDoEn: const Value('Pull out infected plants and bury them now. Plant a resistant variety next season. Plant at the same time as the neighbouring fields.'),
        whatToDoSi: const Value('ආසාදිත පැළ දැන්ම උදුරා වළදමන්න. ඊළඟ කන්නයේ ප්‍රතිරෝධී ප්‍රභේදයක් වවන්න. අසල ලියැදි සමඟ එකවර වගා කරන්න.'),
        whatToDoTa: const Value('பாதிக்கப்பட்ட செடிகளை இப்போதே பிடுங்கி புதைக்கவும். அடுத்த பருவத்தில் எதிர்ப்புத் திறன் உள்ள ரகத்தை நடவும். அருகிலுள்ள வயல்களுடன் ஒரே நேரத்தில் நடவும்.'),
        whatToAvoidEn: const Value('Do not rely on insecticide; it rarely stops tungro. Do not add extra urea. Do not plant at a different time from your neighbours.'),
        whatToAvoidSi: const Value('කෘමිනාශක මත රඳා නොසිටින්න; ඒවා ටංග්‍රෝ නවත්වන්නේ කලාතුරකිනි. අමතර යූරියා නොයොදන්න. අසල්වැසියන්ට වඩා වෙනස් වේලාවක වගා නොකරන්න.'),
        whatToAvoidTa: const Value('பூச்சிக்கொல்லியை நம்பாதீர்கள்; அது துங்க்ரோவை அரிதாகவே தடுக்கும். கூடுதல் யூரியா இடாதீர்கள். அண்டை வயல்களை விட வேறு நேரத்தில் நடாதீர்கள்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-02-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_paddy_dead_heart',
        diseaseId: 'paddy_dead_heart',
        guidelineVersion: 'tg-2026.02',
        summaryEn: const Value('The central shoot dries and pulls out easily. A caterpillar is feeding inside the stem.'),
        summarySi: const Value('මැද දළුව වියළී පහසුවෙන් ගැලවේ. කඳ ඇතුළත දළඹුවෙක් කයි.'),
        summaryTa: const Value('நடுத் தண்டு காய்ந்து எளிதில் பிடுங்கி வரும். தண்டுக்குள் ஒரு புழு உள்ளது.'),
        whatToDoEn: const Value('Pull out the dead shoots and crush the caterpillar inside. Cut the crop at ground level at harvest. Plough in the stubble afterwards.'),
        whatToDoSi: const Value('වියළුණු දළු උදුරා ඇතුළත දළඹුවා මරන්න. අස්වනු නෙළන විට බිම මට්ටමින් කපන්න. පසුව කරල් සී සාන්න.'),
        whatToDoTa: const Value('காய்ந்த தண்டுகளை பிடுங்கி உள்ளே உள்ள புழுவை அழிக்கவும். அறுவடையின் போது தரை மட்டத்தில் வெட்டவும். பின்னர் தாள்களை உழவு செய்யவும்.'),
        whatToAvoidEn: const Value('Do not spray broad-spectrum insecticide; it kills the small wasps that control this pest.'),
        whatToAvoidSi: const Value('පුළුල් පරාසයේ කෘමිනාශක නොඉසින්න; ඒවා මෙම පළිබෝධයා පාලනය කරන කුඩා බඹරුන් මරයි.'),
        whatToAvoidTa: const Value('பரந்த அளவிலான பூச்சிக்கொல்லி தெளிக்காதீர்கள்; அது இப்பூச்சியை கட்டுப்படுத்தும் சிறு குளவிகளை கொல்லும்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-02-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_paddy_hispa',
        diseaseId: 'paddy_hispa',
        guidelineVersion: 'tg-2026.02',
        summaryEn: const Value('Leaves show white parallel scratch marks and later dry up. A small blue-black beetle feeds on them.'),
        summarySi: const Value('පත්‍ර මත සුදු ඉරි ලකුණු පෙනී පසුව වියළේ. කුඩා නිල්-කළු කුරුමිණියෙක් ඒවා කයි.'),
        summaryTa: const Value('இலைகளில் வெள்ளைக் கீறல் கோடுகள் தோன்றி பின் காய்ந்துவிடும். சிறிய நீல-கருப்பு வண்டு இதை உண்கிறது.'),
        whatToDoEn: const Value('Clip and destroy the damaged leaf tips; this removes most of the grubs. Cut the grasses on the bunds and around the field. Use balanced fertiliser.'),
        whatToDoSi: const Value('හානි වූ පත්‍ර අග්‍ර කපා විනාශ කරන්න; මෙයින් බොහෝ පණුවන් ඉවත් වේ. නියරවල සහ ලියැද්ද වටා තණකොළ කපන්න. සමතුලිත පොහොර යොදන්න.'),
        whatToDoTa: const Value('சேதமடைந்த இலை நுனிகளை வெட்டி அழிக்கவும்; இதனால் பெரும்பாலான புழுக்கள் நீங்கும். வரப்பிலும் வயலைச் சுற்றியும் புற்களை வெட்டவும். சமச்சீர் உரமிடவும்.'),
        whatToAvoidEn: const Value('Do not spray early; small wasps control this pest if left alone. Do not add extra urea.'),
        whatToAvoidSi: const Value('ඉක්මනින් නොඉසින්න; තනිව තැබුවහොත් කුඩා බඹරුන් මෙය පාලනය කරයි. අමතර යූරියා නොයොදන්න.'),
        whatToAvoidTa: const Value('சீக்கிரம் தெளிக்காதீர்கள்; தனியே விட்டால் சிறு குளவிகள் இதை கட்டுப்படுத்தும். கூடுதல் யூரியா இடாதீர்கள்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-02-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_cassava_bacterial_blight',
        diseaseId: 'cassava_bacterial_blight',
        guidelineVersion: 'tg-2026.02',
        summaryEn: const Value('Angular water-soaked spots appear on leaves, then the plant wilts and stems die back. Gum may ooze from the stem.'),
        summarySi: const Value('පත්‍ර මත කෝණික තෙත් ලප ඇති වී පසුව පැළය මැලවී කඳ මිය යයි. කඳෙන් මැලියම් වැගිරිය හැක.'),
        summaryTa: const Value('இலைகளில் கோண வடிவ நீர் ஊறிய புள்ளிகள் தோன்றி பின் செடி வாடி தண்டு இறக்கும். தண்டிலிருந்து பசை வடியலாம்.'),
        whatToDoEn: const Value('Remove and burn affected leaves as soon as you see them. Take cuttings only from healthy plants. Clean tools with bleach between plants. Rotate to another crop for one to two years.'),
        whatToDoSi: const Value('දුටු වහාම වැළඳුණු පත්‍ර ඉවත් කර පුළුස්සන්න. නිරෝගී පැළවලින් පමණක් කඳන් ගන්න. පැළෙන් පැළට උපකරණ බ්ලීච් වලින් පිරිසිදු කරන්න. වසරක් දෙකක් වෙනත් බෝගයක් වවන්න.'),
        whatToDoTa: const Value('பாதிக்கப்பட்ட இலைகளைக் கண்டவுடன் அகற்றி எரிக்கவும். ஆரோக்கியமான செடிகளிலிருந்து மட்டுமே குச்சிகள் எடுக்கவும். செடிக்கு செடி கருவிகளை ப்ளீச்சில் கழுவவும். ஒன்று இரண்டு ஆண்டுகள் வேறு பயிர் சுழற்சி செய்யவும்.'),
        whatToAvoidEn: const Value('There is no spray for this disease; do not waste money on one. Do not plant new cassava beside an affected plot.'),
        whatToAvoidSi: const Value('මෙම රෝගයට ඉසින ඖෂධයක් නැත; ඒ සඳහා මුදල් නාස්ති නොකරන්න. වැළඳුණු බිමක් අසල අලුත් මඤ්ඤොක්කා නොවවන්න.'),
        whatToAvoidTa: const Value('இந்நோய்க்கு தெளிப்பான் இல்லை; அதற்காக பணத்தை வீணாக்காதீர்கள். பாதிக்கப்பட்ட நிலத்திற்கு அருகில் புதிய மரவள்ளி நடாதீர்கள்.'),
        recheckAfterDays: const Value(14),
        publishedAt: const Value('2026-02-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_cassava_brown_streak',
        diseaseId: 'cassava_brown_streak',
        guidelineVersion: 'tg-2026.02',
        summaryEn: const Value('Yellow blotches form along the leaf veins, and brown rotten streaks run through the roots. Roots can look fine from outside.'),
        summarySi: const Value('පත්‍ර නාරටි දිගේ කහ පැල්ලම් ඇති වන අතර අල ඇතුළත දුඹුරු කුණු ඉරි දිවේ. අල පිටතින් හොඳින් පෙනිය හැක.'),
        summaryTa: const Value('இலை நரம்புகளில் மஞ்சள் திட்டுகள் தோன்றும், கிழங்குக்குள் பழுப்பு அழுகல் கோடுகள் இருக்கும். கிழங்கு வெளியே நன்றாகத் தெரியலாம்.'),
        whatToDoEn: const Value('Dig up and burn affected plants. Plant only cuttings taken from healthy plants. Plant a tolerant variety if one is available.'),
        whatToDoSi: const Value('වැළඳුණු පැළ හාරා ඉවත් කර පුළුස්සන්න. නිරෝගී පැළවලින් ගත් කඳන් පමණක් සිටුවන්න. ලබා ගත හැකි නම් ඔරොත්තු දෙන ප්‍රභේදයක් වවන්න.'),
        whatToDoTa: const Value('பாதிக்கப்பட்ட செடிகளை தோண்டி எரிக்கவும். ஆரோக்கியமான செடிகளின் குச்சிகளை மட்டும் நடவும். கிடைத்தால் தாங்கும் திறன் உள்ள ரகத்தை நடவும்.'),
        whatToAvoidEn: const Value('Do not replant cuttings from an affected plant, even if the stem looks healthy.'),
        whatToAvoidSi: const Value('කඳ නිරෝගී ලෙස පෙනුණත් වැළඳුණු පැළයකින් කඳන් නොසිටුවන්න.'),
        whatToAvoidTa: const Value('தண்டு நன்றாக இருந்தாலும் பாதிக்கப்பட்ட செடியின் குச்சியை நடாதீர்கள்.'),
        recheckAfterDays: const Value(14),
        publishedAt: const Value('2026-02-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_cassava_green_mottle',
        diseaseId: 'cassava_green_mottle',
        guidelineVersion: 'tg-2026.02',
        summaryEn: const Value('Leaves are mottled, puckered and distorted, and the plant stays small. It spreads mainly through cuttings.'),
        summarySi: const Value('පත්‍ර පැල්ලම් සහිතව රැලි වී විකෘති වන අතර පැළය කුඩාව පවතී. එය ප්‍රධාන වශයෙන් කඳන් මගින් පැතිරේ.'),
        summaryTa: const Value('இலைகள் புள்ளிகளுடன் சுருங்கி வடிவம் மாறும், செடி சிறியதாகவே இருக்கும். இது முக்கியமாக குச்சிகள் மூலம் பரவுகிறது.'),
        whatToDoEn: const Value('Pull out plants showing symptoms and burn them. Take cuttings only from plants with no symptoms.'),
        whatToDoSi: const Value('රෝග ලක්ෂණ ඇති පැළ උදුරා පුළුස්සන්න. රෝග ලක්ෂණ නැති පැළවලින් පමණක් කඳන් ගන්න.'),
        whatToDoTa: const Value('அறிகுறி உள்ள செடிகளை பிடுங்கி எரிக்கவும். அறிகுறி இல்லாத செடிகளிலிருந்து மட்டும் குச்சிகள் எடுக்கவும்.'),
        whatToAvoidEn: const Value('There is no spray for this disease. Do not carry cuttings from an affected garden to a clean one.'),
        whatToAvoidSi: const Value('මෙම රෝගයට ඉසින ඖෂධයක් නැත. වැළඳුණු වත්තකින් පිරිසිදු වත්තකට කඳන් නොගෙන යන්න.'),
        whatToAvoidTa: const Value('இந்நோய்க்கு தெளிப்பான் இல்லை. பாதிக்கப்பட்ட தோட்டத்திலிருந்து சுத்தமான தோட்டத்திற்கு குச்சிகளை கொண்டு செல்லாதீர்கள்.'),
        recheckAfterDays: const Value(14),
        publishedAt: const Value('2026-02-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_cassava_mosaic',
        diseaseId: 'cassava_mosaic',
        guidelineVersion: 'tg-2026.02',
        summaryEn: const Value('Yellow and green patches appear on puckered, twisted leaves and the plant stays small. Whitefly and infected cuttings spread it.'),
        summarySi: const Value('රැලි වූ ඇඹරුණු පත්‍ර මත කහ සහ කොළ පැල්ලම් ඇති වන අතර පැළය කුඩාව පවතී. සුදු මැස්සන් සහ ආසාදිත කඳන් එය පතුරුවයි.'),
        summaryTa: const Value('சுருங்கிய திரிந்த இலைகளில் மஞ்சள் பச்சை திட்டுகள் தோன்றும், செடி சிறியதாகவே இருக்கும். வெள்ளை ஈக்களும் பாதித்த குச்சிகளும் பரப்பும்.'),
        whatToDoEn: const Value('Pull out and burn affected plants early. Plant only cuttings from healthy plants. Plant a resistant variety if one is available.'),
        whatToDoSi: const Value('වැළඳුණු පැළ කල් තියා උදුරා පුළුස්සන්න. නිරෝගී පැළවලින් පමණක් කඳන් සිටුවන්න. ලබා ගත හැකි නම් ප්‍රතිරෝධී ප්‍රභේදයක් වවන්න.'),
        whatToDoTa: const Value('பாதிக்கப்பட்ட செடிகளை முன்கூட்டியே பிடுங்கி எரிக்கவும். ஆரோக்கியமான செடிகளின் குச்சிகளை மட்டும் நடவும். கிடைத்தால் எதிர்ப்புத் திறன் உள்ள ரகத்தை நடவும்.'),
        whatToAvoidEn: const Value('Do not take cuttings from a plant with mosaic. Do not leave affected plants standing in the plot.'),
        whatToAvoidSi: const Value('මොසෙයික් ඇති පැළයකින් කඳන් නොගන්න. වැළඳුණු පැළ බිමේ තබා නොගන්න.'),
        whatToAvoidTa: const Value('மொசைக் உள்ள செடியிலிருந்து குச்சி எடுக்காதீர்கள். பாதிக்கப்பட்ட செடிகளை நிலத்தில் விடாதீர்கள்.'),
        recheckAfterDays: const Value(14),
        publishedAt: const Value('2026-02-01T00:00:00Z'),
      ),
    ];

    for (final guideline in guidelines) {
      await db.into(db.treatmentGuidelineTable).insertOnConflictUpdate(guideline);
    }
  }

  /// Returns the disease entity matching [diseaseId], or null.
  Future<DiseaseTableData?> getDiseaseById(String diseaseId) async {
    final result = await (db.select(db.diseaseTable)
          ..where((t) => t.id.equals(diseaseId)))
        .getSingleOrNull();
    return result;
  }
}

// ---------------------------------------------------------------------------
// CLASS_NAMES — 38 PlantVillage output classes in model-index order.
// This list is the single source of truth used by MlInferenceService to map
// a raw output index → disease id stored in SQLite.
// ---------------------------------------------------------------------------
//
// Index → disease_id mapping (only supported crops kept):
//   18 → chili_bacterial_spot
//   19 → chili_healthy
//   28 → tomato_bacterial_spot
//   29 → tomato_early_blight
//   30 → tomato_late_blight
//   31 → tomato_leaf_mold
//   32 → tomato_septoria_leaf_spot
//   33 → tomato_spider_mites
//   34 → tomato_target_spot
//   35 → tomato_yellow_leaf_curl_virus
//   36 → tomato_mosaic_virus
//   37 → tomato_healthy
//   All others → unsupported crop → result_state = 'UNSUPPORTED'
//
// Full list (do not reorder — index == model output position):
// [0]  Apple___Apple_scab
// [1]  Apple___Black_rot
// [2]  Apple___Cedar_apple_rust
// [3]  Apple___healthy
// [4]  Blueberry___healthy
// [5]  Cherry_(including_sour)___Powdery_mildew
// [6]  Cherry_(including_sour)___healthy
// [7]  Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot
// [8]  Corn_(maize)___Common_rust_
// [9]  Corn_(maize)___Northern_Leaf_Blight
// [10] Corn_(maize)___healthy
// [11] Grape___Black_rot
// [12] Grape___Esca_(Black_Measles)
// [13] Grape___Leaf_blight_(Isariopsis_Leaf_Spot)
// [14] Grape___healthy
// [15] Orange___Haunglongbing_(Citrus_greening)
// [16] Peach___Bacterial_spot
// [17] Peach___healthy
// [18] Pepper,_bell___Bacterial_spot       → chili_bacterial_spot
// [19] Pepper,_bell___healthy              → chili_healthy
// [20] Potato___Early_blight
// [21] Potato___Late_blight
// [22] Potato___healthy
// [23] Raspberry___healthy
// [24] Soybean___healthy
// [25] Squash___Powdery_mildew
// [26] Strawberry___Leaf_scorch
// [27] Strawberry___healthy
// [28] Tomato___Bacterial_spot             → tomato_bacterial_spot
// [29] Tomato___Early_blight               → tomato_early_blight
// [30] Tomato___Late_blight                → tomato_late_blight
// [31] Tomato___Leaf_Mold                  → tomato_leaf_mold
// [32] Tomato___Septoria_leaf_spot         → tomato_septoria_leaf_spot
// [33] Tomato___Spider_mites Two-spotted   → tomato_spider_mites
// [34] Tomato___Target_Spot                → tomato_target_spot
// [35] Tomato___Tomato_Yellow_Leaf_Curl_Virus → tomato_yellow_leaf_curl_virus
// [36] Tomato___Tomato_mosaic_virus        → tomato_mosaic_virus
// [37] Tomato___healthy                    → tomato_healthy
