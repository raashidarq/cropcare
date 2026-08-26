import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:cropcare/domain/usecases/diagnosis/validate_image_use_case.dart';

/// Writes a synthetic checkerboard-pattern PNG (adds enough high-frequency
/// detail to (a) clear the min-file-size check after PNG compression and
/// (b) clear the blur/sharpness check, unless [blurRadius] is supplied) and
/// returns its path. [colorA]/[colorB] alternate in `blockSize`-px squares.
Future<String> _writeCheckerboard(
  Directory dir,
  String name, {
  required img.Color colorA,
  required img.Color colorB,
  int size = 200,
  int blockSize = 10,
  int? blurRadius,
  int noiseAmplitude = 5,
}) async {
  var image = img.Image(width: size, height: size);
  final rand = Random(7);
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final isA = ((x ~/ blockSize) + (y ~/ blockSize)).isEven;
      final base = isA ? colorA : colorB;
      int jitter() => rand.nextInt(noiseAmplitude * 2 + 1) - noiseAmplitude;
      image.setPixel(
        x,
        y,
        img.ColorRgb8(
          (base.r.toInt() + jitter()).clamp(0, 255),
          (base.g.toInt() + jitter()).clamp(0, 255),
          (base.b.toInt() + jitter()).clamp(0, 255),
        ),
      );
    }
  }
  if (blurRadius != null) {
    image = img.gaussianBlur(image, radius: blurRadius);
  }
  final path = '${dir.path}/$name.png';
  await File(path).writeAsBytes(img.encodePng(image));
  return path;
}

/// Writes a synthetic near-solid PNG with light per-pixel noise (so PNG
/// compression can't shrink it below the min-file-size threshold) and
/// returns its path.
Future<String> _writeNoisySolid(
  Directory dir,
  String name, {
  required int r,
  required int g,
  required int b,
  int size = 200,
  int noiseAmplitude = 4,
}) async {
  final image = img.Image(width: size, height: size);
  final rand = Random(42);
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      int jitter() => rand.nextInt(noiseAmplitude * 2 + 1) - noiseAmplitude;
      image.setPixel(
        x,
        y,
        img.ColorRgb8(
          (r + jitter()).clamp(0, 255),
          (g + jitter()).clamp(0, 255),
          (b + jitter()).clamp(0, 255),
        ),
      );
    }
  }
  final path = '${dir.path}/$name.png';
  await File(path).writeAsBytes(img.encodePng(image));
  return path;
}

void main() {
  late Directory tempDir;
  late ValidateImageUseCase useCase;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cropcare_validate_test_');
    useCase = ValidateImageUseCase();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ValidateImageUseCase — file-level checks (existing behavior)', () {
    test('rejects a nonexistent file as fileNotFound', () async {
      final result = await useCase('${tempDir.path}/does_not_exist.png');
      expect(result.isUsable, isFalse);
      expect(result.rejectionReason, ImageRejectionReason.fileNotFound);
    });

    test('rejects a too-small file as fileTooSmall', () async {
      final path = '${tempDir.path}/tiny.png';
      await File(path).writeAsBytes(List.filled(100, 0));
      final result = await useCase(path);
      expect(result.isUsable, isFalse);
      expect(result.rejectionReason, ImageRejectionReason.fileTooSmall);
    });

    test('rejects an image below the minimum dimension as imageTooSmall', () async {
      final path = await _writeCheckerboard(
        tempDir,
        'small',
        colorA: img.ColorRgb8(40, 160, 40),
        colorB: img.ColorRgb8(20, 100, 20),
        size: 90,
        blockSize: 3,
        noiseAmplitude: 20,
      );
      final result = await useCase(path);
      expect(result.isUsable, isFalse);
      expect(result.rejectionReason, ImageRejectionReason.imageTooSmall);
    });
  });

  group('ValidateImageUseCase — content-quality gate (OOD defense)', () {
    test('accepts a sharp, well-lit, vegetation-hued image', () async {
      final path = await _writeCheckerboard(
        tempDir,
        'leaf_like',
        colorA: img.ColorRgb8(40, 150, 40),
        colorB: img.ColorRgb8(20, 90, 25),
      );
      final result = await useCase(path);
      expect(result.isUsable, isTrue);
      expect(result.rejectionReason, isNull);
    });

    test('rejects a near-black (too dark) photo', () async {
      final path = await _writeNoisySolid(tempDir, 'dark', r: 5, g: 5, b: 5);
      final result = await useCase(path);
      expect(result.isUsable, isFalse);
      expect(result.rejectionReason, ImageRejectionReason.tooDark);
    });

    test('rejects a near-white (overexposed) photo', () async {
      final path = await _writeNoisySolid(tempDir, 'bright', r: 250, g: 250, b: 250);
      final result = await useCase(path);
      expect(result.isUsable, isFalse);
      expect(result.rejectionReason, ImageRejectionReason.tooBright);
    });

    test('rejects a heavily blurred photo as blurry', () async {
      final path = await _writeCheckerboard(
        tempDir,
        'blurred',
        colorA: img.ColorRgb8(110, 110, 110),
        colorB: img.ColorRgb8(150, 150, 150),
        size: 400,
        blockSize: 6,
        noiseAmplitude: 8,
        blurRadius: 12,
      );
      final result = await useCase(path);
      expect(result.isUsable, isFalse);
      expect(result.rejectionReason, ImageRejectionReason.blurry);
    });

    test(
      'REGRESSION: a photo of a desk (sharp, well-lit, non-green) does not '
      'pass validation — this is the reported bug (a desk photo was '
      'confidently diagnosed as "Tomato Healthy" at 98%)',
      () async {
        final path = await _writeCheckerboard(
          tempDir,
          'desk',
          colorA: img.ColorRgb8(150, 120, 90), // wood-tone
          colorB: img.ColorRgb8(120, 95, 70),
        );
        final result = await useCase(path);
        expect(result.isUsable, isFalse);
        expect(result.rejectionReason, ImageRejectionReason.noPlantDetected);
      },
    );

    test('rejects a gray/desaturated (no vegetation) sharp photo', () async {
      final path = await _writeCheckerboard(
        tempDir,
        'gray_desk',
        colorA: img.ColorRgb8(130, 130, 130),
        colorB: img.ColorRgb8(100, 100, 100),
      );
      final result = await useCase(path);
      expect(result.isUsable, isFalse);
      expect(result.rejectionReason, ImageRejectionReason.noPlantDetected);
    });
  });

  group('rejectionReasonToString', () {
    test('maps every reason to the schema-reserved vocabulary', () {
      expect(
        ValidateImageUseCase.rejectionReasonToString(ImageRejectionReason.fileNotFound),
        'FILE_NOT_FOUND',
      );
      expect(
        ValidateImageUseCase.rejectionReasonToString(ImageRejectionReason.fileTooSmall),
        'LOW_RESOLUTION',
      );
      expect(
        ValidateImageUseCase.rejectionReasonToString(ImageRejectionReason.corruptImage),
        'UNSUPPORTED_FORMAT',
      );
      expect(
        ValidateImageUseCase.rejectionReasonToString(ImageRejectionReason.imageTooSmall),
        'LOW_RESOLUTION',
      );
      expect(
        ValidateImageUseCase.rejectionReasonToString(ImageRejectionReason.tooDark),
        'TOO_DARK',
      );
      expect(
        ValidateImageUseCase.rejectionReasonToString(ImageRejectionReason.tooBright),
        'TOO_BRIGHT',
      );
      expect(
        ValidateImageUseCase.rejectionReasonToString(ImageRejectionReason.blurry),
        'BLURRY',
      );
      expect(
        ValidateImageUseCase.rejectionReasonToString(ImageRejectionReason.noPlantDetected),
        'NO_PLANT_DETECTED',
      );
    });
  });
}
