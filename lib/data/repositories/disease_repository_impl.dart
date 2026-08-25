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
