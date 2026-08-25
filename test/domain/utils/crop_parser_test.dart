import 'package:flutter_test/flutter_test.dart';
import 'package:cropcare/domain/utils/crop_parser.dart';

void main() {
  group('CropParser.deriveCropId', () {
    test('correctly derives single-word crops from raw model class names', () {
      expect(CropParser.deriveCropId('Tomato___Early_blight'), equals('tomato'));
      expect(CropParser.deriveCropId('Tomato___healthy'), equals('tomato'));
      expect(CropParser.deriveCropId('Potato___Late_blight'), equals('potato'));
      expect(CropParser.deriveCropId('Apple___Apple_scab'), equals('apple'));
      expect(CropParser.deriveCropId('Grape___Black_rot'), equals('grape'));
      expect(CropParser.deriveCropId('Peach___Bacterial_spot'), equals('peach'));
      expect(CropParser.deriveCropId('Strawberry___healthy'), equals('strawberry'));
      expect(CropParser.deriveCropId('Squash___Powdery_mildew'), equals('squash'));
      expect(CropParser.deriveCropId('Soybean___healthy'), equals('soybean'));
    });

    test('correctly derives multi-word and formatted crops from raw model class names', () {
      expect(CropParser.deriveCropId('Pepper,_bell___Bacterial_spot'), equals('chili'));
      expect(CropParser.deriveCropId('Pepper,_bell___healthy'), equals('chili'));
      expect(CropParser.deriveCropId('Corn_(maize)___Common_rust_'), equals('corn'));
      expect(CropParser.deriveCropId('Corn_(maize)___Northern_Leaf_Blight'), equals('corn'));
      expect(CropParser.deriveCropId('Cherry_(including_sour)___Powdery_mildew'), equals('cherry'));
      expect(CropParser.deriveCropId('Orange___Haunglongbing_(Citrus_greening)'), equals('orange'));
    });

    test('correctly derives crops from disease ID strings', () {
      expect(CropParser.deriveCropId('tomato_early_blight'), equals('tomato'));
      expect(CropParser.deriveCropId('chili_bacterial_spot'), equals('chili'));
      expect(CropParser.deriveCropId('potato_late_blight'), equals('potato'));
      expect(CropParser.deriveCropId('corn_gray_leaf_spot'), equals('corn'));
      expect(CropParser.deriveCropId('apple_scab'), equals('apple'));
      expect(CropParser.deriveCropId('paddy_blast'), equals('paddy'));
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
