// lib/domain/usecases/diagnosis/validate_image_use_case.dart
//
// Image quality + content gate that runs BEFORE ML inference.
// Keeps every check lightweight and on-device (no network).
//
// Checks, cheapest-first, short-circuiting on the first failure:
//   1. File exists at the given path.
//   2. File size > 5 KB (catches empty/corrupt writes).
//   3. File can be decoded as a valid image.
//   4. Both dimensions >= 100 px (too small = likely garbage).
//   5. Mean luminance is neither too dark nor overexposed.
//   6. The image isn't extremely blurry (cheap Laplacian-variance estimate).
//   7. The image contains enough vegetation-hued pixels to plausibly be a
//      plant/leaf photo (HSV hue/saturation heuristic).
//
// Checks 5-7 exist specifically to reject out-of-distribution photos (a
// desk, a blank sheet of paper, a hand, a wall, ...) BEFORE they reach the
// closed-set 38-class classifier, which — being a plain softmax over a
// fixed class list — will otherwise always produce a confident-looking
// answer for any input (see MlInferenceService). These are pragmatic,
// no-retraining-required heuristics, not a substitute for a trained
// leaf-vs-not-leaf classifier; thresholds are named constants below so
// they can be recalibrated from field data without restructuring the code.
//
// Does NOT write to the image_validation table — that is the caller's
// (RunDiagnosisUseCase's) responsibility so it can attach the scan ID.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

enum ImageRejectionReason {
  fileNotFound,
  fileTooSmall,
  corruptImage,
  imageTooSmall,
  tooDark,
  tooBright,
  blurry,
  noPlantDetected,
}

class ImageValidationResult {
  final bool isUsable;
  final ImageRejectionReason? rejectionReason;

  const ImageValidationResult.valid()
      : isUsable = true,
        rejectionReason = null;

  const ImageValidationResult.invalid(this.rejectionReason) : isUsable = false;
}

class ValidateImageUseCase {
  static const int _minFileSizeBytes = 5 * 1024; // 5 KB
  static const int _minDimension = 100; // px

  // Shared downsampled working size for the cheap content-quality checks
  // below — keeps them fast even on a low-end device regardless of the
  // original photo's resolution.
  static const int _sampleSize = 64;

  // Mean luminance (0-255) outside this band is rejected as too dark /
  // overexposed. A desk in a dim room or a photo taken pointed at a bright
  // light/sky also tends to fail one of these two bounds.
  static const double _minMeanLuminance = 25.0;
  static const double _maxMeanLuminance = 235.0;

  // Laplacian-variance sharpness estimate over the downsampled grayscale
  // sample. Deliberately conservative (low) so only clearly out-of-focus
  // photos are rejected — false-rejecting a slightly soft but usable leaf
  // photo is worse than letting a mildly blurry one through.
  static const double _minSharpnessVariance = 6.0;

  // Fraction of sampled pixels that must fall in the "vegetation" hue band
  // with enough saturation to plausibly be leaf material. Kept low (12%)
  // on purpose: a diseased leaf may be mostly brown/yellow, and a photo
  // may include leaf plus background — this only needs to catch the
  // "there is essentially no plant material in frame at all" case (a desk,
  // a blank wall, a piece of paper, a hand).
  static const double _minVegetationFraction = 0.12;

  Future<ImageValidationResult> call(String imageLocalPath) async {
    final file = File(imageLocalPath);

    // 1. Existence check
    if (!file.existsSync()) {
      return const ImageValidationResult.invalid(
        ImageRejectionReason.fileNotFound,
      );
    }

    // 2. Size check
    final size = await file.length();
    if (size < _minFileSizeBytes) {
      return const ImageValidationResult.invalid(
        ImageRejectionReason.fileTooSmall,
      );
    }

    // 3. Decode check
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) {
      return const ImageValidationResult.invalid(
        ImageRejectionReason.corruptImage,
      );
    }

    // 4. Dimension check
    if (decoded.width < _minDimension || decoded.height < _minDimension) {
      return const ImageValidationResult.invalid(
        ImageRejectionReason.imageTooSmall,
      );
    }

    // Single shared downsample for all remaining content-quality checks —
    // avoids re-decoding/re-resizing per check.
    final sample = img.copyResize(
      decoded,
      width: _sampleSize,
      height: _sampleSize,
    );

    // 5. Exposure check
    final meanLuminance = _meanLuminance(sample);
    if (meanLuminance < _minMeanLuminance) {
      return const ImageValidationResult.invalid(ImageRejectionReason.tooDark);
    }
    if (meanLuminance > _maxMeanLuminance) {
      return const ImageValidationResult.invalid(
        ImageRejectionReason.tooBright,
      );
    }

    // 6. Blur check
    if (_laplacianVariance(sample) < _minSharpnessVariance) {
      return const ImageValidationResult.invalid(ImageRejectionReason.blurry);
    }

    // 7. Vegetation/content check — the primary defense against confidently
    // diagnosing a photo that isn't a plant at all.
    if (_vegetationFraction(sample) < _minVegetationFraction) {
      return const ImageValidationResult.invalid(
        ImageRejectionReason.noPlantDetected,
      );
    }

    return const ImageValidationResult.valid();
  }

  /// Maps [ImageRejectionReason] to the string stored in SQLite.
  /// Matches the vocabulary already reserved in `image_validation.rejection_reason`
  /// (see tables.dart).
  static String rejectionReasonToString(ImageRejectionReason reason) {
    switch (reason) {
      case ImageRejectionReason.fileNotFound:
        return 'FILE_NOT_FOUND';
      case ImageRejectionReason.fileTooSmall:
        return 'LOW_RESOLUTION';
      case ImageRejectionReason.corruptImage:
        return 'UNSUPPORTED_FORMAT';
      case ImageRejectionReason.imageTooSmall:
        return 'LOW_RESOLUTION';
      case ImageRejectionReason.tooDark:
        return 'TOO_DARK';
      case ImageRejectionReason.tooBright:
        return 'TOO_BRIGHT';
      case ImageRejectionReason.blurry:
        return 'BLURRY';
      case ImageRejectionReason.noPlantDetected:
        return 'NO_PLANT_DETECTED';
    }
  }

  // ---------------------------------------------------------------------------
  // Content-quality heuristics (operate on the small `sample` image)
  // ---------------------------------------------------------------------------

  double _meanLuminance(img.Image sample) {
    double sum = 0;
    int count = 0;
    for (int y = 0; y < sample.height; y++) {
      for (int x = 0; x < sample.width; x++) {
        final p = sample.getPixel(x, y);
        sum += 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
        count++;
      }
    }
    return count == 0 ? 0 : sum / count;
  }

  double _laplacianVariance(img.Image sample) {
    final w = sample.width;
    final h = sample.height;
    // Precompute grayscale intensity grid once.
    final intensity = List.generate(
      h,
      (y) => List.generate(w, (x) {
        final p = sample.getPixel(x, y);
        return 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      }),
    );

    final responses = <double>[];
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final laplacian = 4 * intensity[y][x] -
            intensity[y - 1][x] -
            intensity[y + 1][x] -
            intensity[y][x - 1] -
            intensity[y][x + 1];
        responses.add(laplacian);
      }
    }
    if (responses.isEmpty) return 0;

    final mean = responses.reduce((a, b) => a + b) / responses.length;
    final variance = responses
            .map((r) => (r - mean) * (r - mean))
            .reduce((a, b) => a + b) /
        responses.length;
    return variance;
  }

  double _vegetationFraction(img.Image sample) {
    int vegetationPixels = 0;
    int total = 0;
    for (int y = 0; y < sample.height; y++) {
      for (int x = 0; x < sample.width; x++) {
        final p = sample.getPixel(x, y);
        final hsv = _rgbToHsv(p.r.toDouble(), p.g.toDouble(), p.b.toDouble());
        total++;
        // Vegetation hue band: yellow-green through green to green-cyan,
        // with enough saturation/value to exclude gray desks, white paper,
        // and near-black shadow.
        final hue = hsv.$1;
        final saturation = hsv.$2;
        final value = hsv.$3;
        if (hue >= 60 &&
            hue <= 170 &&
            saturation >= 0.15 &&
            value >= 0.10) {
          vegetationPixels++;
        }
      }
    }
    return total == 0 ? 0 : vegetationPixels / total;
  }

  /// Returns (hue in degrees [0,360), saturation [0,1], value [0,1]).
  (double, double, double) _rgbToHsv(double r255, double g255, double b255) {
    final r = r255 / 255.0;
    final g = g255 / 255.0;
    final b = b255 / 255.0;

    final maxC = math.max(r, math.max(g, b));
    final minC = math.min(r, math.min(g, b));
    final delta = maxC - minC;

    double hue;
    if (delta == 0) {
      hue = 0;
    } else if (maxC == r) {
      hue = 60 * (((g - b) / delta) % 6);
    } else if (maxC == g) {
      hue = 60 * (((b - r) / delta) + 2);
    } else {
      hue = 60 * (((r - g) / delta) + 4);
    }
    if (hue < 0) hue += 360;

    final saturation = maxC == 0 ? 0.0 : delta / maxC;
    final value = maxC;

    return (hue, saturation, value);
  }
}
