// lib/domain/utils/crop_parser.dart
//
// Utility for extracting and normalizing crop_id from ML model prediction classes
// or disease identifiers.

class CropParser {
  /// Maps raw model class names (e.g. 'Tomato___Early_blight', 'Pepper,_bell___Bacterial_spot',
  /// 'Corn_(maize)___Northern_Leaf_Blight', 'Cherry_(including_sour)___healthy')
  /// or disease identifiers (e.g. 'tomato_early_blight', 'chili_bacterial_spot')
  /// to supported crop IDs in the local database.
  ///
  /// Falls back to 'unknown' if no supported crop is matched.
  static String deriveCropId(String? classNameOrDiseaseId) {
    if (classNameOrDiseaseId == null || classNameOrDiseaseId.trim().isEmpty) {
      return 'unknown';
    }

    final input = classNameOrDiseaseId.trim();

    // 1. If raw class name formatted with '___' separator (e.g. 'Tomato___Early_blight')
    if (input.contains('___')) {
      final rawCropPart = input.split('___').first.trim().toLowerCase();
      final matched = _matchCropToken(rawCropPart);
      if (matched != null) return matched;
    }

    // 2. If disease identifier formatted with '_' (e.g. 'tomato_early_blight', 'chili_healthy')
    final diseaseLower = input.toLowerCase();
    final matchedDisease = _matchCropToken(diseaseLower);
    if (matchedDisease != null) return matchedDisease;

    return 'unknown';
  }

  static String? _matchCropToken(String token) {
    // Check specific/multi-word patterns first
    if (token.contains('pepper') ||
        token.contains('chili') ||
        token.contains('bell')) {
      return 'chili';
    }
    if (token.contains('tomato')) return 'tomato';
    if (token.contains('potato')) return 'potato';
    if (token.contains('corn') || token.contains('maize')) return 'corn';
    if (token.contains('apple')) return 'apple';
    if (token.contains('grape')) return 'grape';
    if (token.contains('cherry')) return 'cherry';
    if (token.contains('orange') || token.contains('citrus')) return 'orange';
    if (token.contains('peach')) return 'peach';
    if (token.contains('strawberry')) return 'strawberry';
    if (token.contains('blueberry')) return 'blueberry';
    if (token.contains('raspberry')) return 'raspberry';
    if (token.contains('soybean')) return 'soybean';
    if (token.contains('squash')) return 'squash';
    if (token.contains('paddy') || token.contains('rice')) return 'paddy';

    return null;
  }
}
