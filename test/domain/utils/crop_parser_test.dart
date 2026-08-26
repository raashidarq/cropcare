import 'package:flutter_test/flutter_test.dart';
import 'package:cropcare/domain/utils/crop_parser.dart';

void main() {
  group('CropParser.deriveCropId', () {
    test('correctly derives single-word crops from raw model class names', () {
      expect(CropParser.deriveCropId('Tomato___Early_blight'), equals('tomato'));
      expect(CropParser.deriveCropId('Tomato___healthy'), equals('tomato'));
      expect(CropParser.deriveCropId('Potato___Late_blight'), equals('potato'));
    });

    test('temperate fruit is no longer recognised', () {
      // The field model does not predict these, and their crop rows are gone.
      // Matching them would leave scan.crop_id pointing at a row that does
      // not exist - foreign keys are not enforced at runtime here, so that
      // would be a silent orphan rather than an error.
      for (final raw in [
        'Apple___Apple_scab',
        'Grape___Black_rot',
        'Peach___Bacterial_spot',
        'Strawberry___healthy',
        'Squash___Powdery_mildew',
        'Soybean___healthy',
      ]) {
        expect(CropParser.deriveCropId(raw), equals('unknown'), reason: raw);
      }
    });

    test('correctly derives multi-word and formatted crops from raw model class names', () {
      expect(CropParser.deriveCropId('Pepper,_bell___Bacterial_spot'), equals('chili'));
      expect(CropParser.deriveCropId('Pepper,_bell___healthy'), equals('chili'));
      expect(CropParser.deriveCropId('Corn_(maize)___Common_rust_'), equals('corn'));
      expect(CropParser.deriveCropId('Corn_(maize)___Northern_Leaf_Blight'), equals('corn'));
      expect(CropParser.deriveCropId('Cherry_(including_sour)___Powdery_mildew'), equals('unknown'));
      expect(CropParser.deriveCropId('Orange___Haunglongbing_(Citrus_greening)'), equals('unknown'));
    });

    test('correctly derives crops from disease ID strings', () {
      expect(CropParser.deriveCropId('tomato_early_blight'), equals('tomato'));
      expect(CropParser.deriveCropId('chili_bacterial_spot'), equals('chili'));
      expect(CropParser.deriveCropId('potato_late_blight'), equals('potato'));
      expect(CropParser.deriveCropId('corn_gray_leaf_spot'), equals('corn'));
      expect(CropParser.deriveCropId('paddy_blast'), equals('paddy'));
      // New with the field model. Without a cassava branch every cassava
      // scan derived a crop of 'unknown'.
      expect(CropParser.deriveCropId('cassava_mosaic'), equals('cassava'));
      expect(CropParser.deriveCropId('cassava_healthy'), equals('cassava'));
    });

    test('defensively falls back to unknown on unmapped, empty, or null inputs', () {
      expect(CropParser.deriveCropId(null), equals('unknown'));
      expect(CropParser.deriveCropId(''), equals('unknown'));
      expect(CropParser.deriveCropId('   '), equals('unknown'));
      expect(CropParser.deriveCropId('Banana___Sigatoka'), equals('unknown'));
      expect(CropParser.deriveCropId('UnknownDiseaseXYZ'), equals('unknown'));
      expect(CropParser.deriveCropId('some_unsupported_disease_123'), equals('unknown'));
    });
  });
}
