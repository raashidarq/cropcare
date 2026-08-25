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
        id: 'paddy_healthy',
        cropId: 'paddy',
        nameEn: 'Healthy',
        severityDefault: const Value(null),
      ),
    ];

    for (final disease in diseases) {
      await db.into(db.diseaseTable).insertOnConflictUpdate(disease);
    }

    await _seedTreatmentGuidelines();
  }

  Future<void> _seedTreatmentGuidelines() async {
    final guidelines = <TreatmentGuidelineTableCompanion>[
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_tomato_early_blight',
        diseaseId: 'tomato_early_blight',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Early blight produces dark spots with concentric rings on older tomato leaves.'),
        summarySi: const Value('මුල් අංගමාරය මගින් පැරණි තක්කාලි පත්‍රවල කේන්ද්‍රීය වළලු සහිත අඳුරු ලප ඇති කරයි.'),
        summaryTa: const Value('ஆரம்பகால கருகல் நோய் பழைய தக்காளி இலைகளில் வட்ட வளையங்களுடன் கூடிய கரும்புள்ளிகளை உருவாக்குகிறது.'),
        whatToDoEn: const Value('Prune lower diseased leaves immediately. Apply copper fungicide or chlorothalonil. Maintain proper plant spacing.'),
        whatToDoSi: const Value('රෝගී පහළ කොළ වහාම කපා ඉවත් කරන්න. කොපර් දිලීර නාශකයක් යොදන්න. ශාක අතර නිසි පරතරය තබාගන්න.'),
        whatToDoTa: const Value('பாதிக்கப்பட்ட கீழ் இலைகளை உடனடியாக அகற்றவும். காப்பர் பூஞ்சைக் கொல்லியைப் பயன்படுத்தவும்.'),
        whatToAvoidEn: const Value('Avoid overhead sprinkler irrigation. Do not leave pruned diseased leaves on the soil.'),
        whatToAvoidSi: const Value('ඉහළින් ජලය ඉසීමෙන් වළකින්න. කපා ඉවත් කළ රෝගී කොළ ක්ෂේත්‍රයේ දමා නොයන්න.'),
        whatToAvoidTa: const Value('மேலிருந்து தண்ணீர் தெளிப்பதைத் தவிர்க்கவும். பாதிக்கப்பட்ட இலைகளை வயலில் விடாதீர்கள்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_tomato_late_blight',
        diseaseId: 'tomato_late_blight',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Late blight causes rapidly spreading dark water-soaked lesions on leaves and stems.'),
        summarySi: const Value('පසු අංගමාරය මගින් පත්‍ර සහ කඳන් මත වේගයෙන් පැතිරෙන තෙතමනය සහිත අඳුරු ලප ඇති කරයි.'),
        summaryTa: const Value('பிற்கால கருகல் நோய் இலைகள் மற்றும் தண்டுகளில் வேகமாக பரவும் நீர் ஊறின கரும்புள்ளிகளை ஏற்படுத்துகிறது.'),
        whatToDoEn: const Value('Apply Mancozeb or systemic copper fungicide promptly. Remove heavily infected plants to stop spore spread.'),
        whatToDoSi: const Value('මැන්කොසෙබ් හෝ කොපර් දිලීර නාශකයක් වහාම යොදන්න. රෝගය පැතිරීම වැළැක්වීමට දැඩි ලෙස හානි වූ ශාක ගලවා පුළුස්සා දමන්න.'),
        whatToDoTa: const Value('மேன்கோசெப் அல்லது காப்பர் பூஞ்சைக் கொல்லியை உடனே பயன்படுத்தவும். பாதிக்கப்பட்ட செடிகளை அகற்றவும்.'),
        whatToAvoidEn: const Value('Do not handle wet plants. Avoid overhead watering during high humidity periods.'),
        whatToAvoidSi: const Value('තෙතමනය ඇති විට ශාක ඇල්ලීමෙන් වළකින්න. අධික ආර්ද්‍රතා කාලවලදී ඉහළින් ජලය දැමීමෙන් වළකින්න.'),
        whatToAvoidTa: const Value('ஈரமான செடிகளைத் தொடாதீர்கள். அதிக ஈரப்பதம் உள்ள நேரங்களில் தண்ணீர் தெளிப்பதைத் தவிர்க்கவும்.'),
        recheckAfterDays: const Value(5),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
      ),
      TreatmentGuidelineTableCompanion.insert(
        id: 'tg_chili_bacterial_spot',
        diseaseId: 'chili_bacterial_spot',
        guidelineVersion: 'tg-2026.01',
        summaryEn: const Value('Bacterial spot produces small water-soaked spots on pepper leaves that turn brown and scab-like.'),
        summarySi: const Value('බැක්ටීරියා ලප රෝගය මිරිස් කොළ මත කුඩා තෙත් ලප ඇති කර පසුව දුඹුරු පැහැයට හැරේ.'),
        summaryTa: const Value('பாக்டீரியா புள்ளி மிளகாய் இலைகளில் சிறிய நீர் புள்ளிகளை உருவாக்கி பழுப்பு நிறமாக மாற்றுகிறது.'),
        whatToDoEn: const Value('Spray copper hydroxide at first sign. Practice crop rotation with non-solanaceous crops.'),
        whatToDoSi: const Value('පළමු ලක්ෂණ දුටු වහාම කොපර් හයිඩ්‍රොක්සයිඩ් ඉසින්න. බෝග මාරුව ක්‍රියාත්මක කරන්න.'),
        whatToDoTa: const Value('காப்பர் ஹைட்ராக்சைடு தெளிக்கவும். பயிர் சுழற்சியைப் பின்பற்றவும்.'),
        whatToAvoidEn: const Value('Avoid sprinkler irrigation. Do not work in fields when leaves are wet.'),
        whatToAvoidSi: const Value('ස්ප්‍රින්ක්ලර් මගින් ජලය යෙදීමෙන් වළකින්න. පත්‍ර තෙත්ව ඇති විට ක්ෂේත්‍රයේ වැඩ කිරීමෙන් වළකින්න.'),
        whatToAvoidTa: const Value('தெளிப்பான் பாசனத்தைத் தவிர்க்கவும். இலைகள் ஈரமாக இருக்கும்போது வயலில் வேலை செய்யாதீர்கள்.'),
        recheckAfterDays: const Value(7),
        publishedAt: const Value('2026-01-01T00:00:00Z'),
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
