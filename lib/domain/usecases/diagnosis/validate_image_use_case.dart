// lib/domain/usecases/diagnosis/validate_image_use_case.dart
//
// Basic image quality validation before ML inference.
// Keeps the check lightweight and on-device (no network).
//
// Checks:
//   1. File exists at the given path.
//   2. File size > 5 KB (catches empty/corrupt writes).
//   3. File can be decoded as a valid image.
//   4. Both dimensions >= 100 px (too small = likely garbage).
//
// Does NOT write to the image_validation table — that is the caller's
// (RunDiagnosisUseCase's) responsibility so it can attach the scan ID.

import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

enum ImageRejectionReason {
  fileNotFound,
  fileTooSmall,
  corruptImage,
  imageTooSmall,
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
  static const int _minDimension = 100;           // px

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

    return const ImageValidationResult.valid();
  }

  /// Maps [ImageRejectionReason] to the string stored in SQLite.
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
    }
  }
}
