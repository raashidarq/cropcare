// lib/data/local/ml/ml_inference_service.dart
//
// On-device TFLite inference using tflite_flutter ^0.12.0.
//
// Model: cropcare_field_mobilenetv3_fp16.tflite (see ml/README.md)
//   - Input:  [1, 224, 224, 3]  float32  NHWC, values [0,1]
//   - Output: [1, 34]           float32  raw logits (NOT softmax)
//   - Preprocessing: resize to 224×224, normalize to [0,1] (divide by 255)
//
// CLASS_NAMES order matches the 34-element output vector, defined by
// ml/taxonomy.py and regenerated via `python ml/build_notebook.py`.
// All 38 output classes map to a disease ID in our DB (see TD-006) — the
// `isSupported`/`unsupported` result state is therefore no longer reachable
// from a normal model prediction; it only exists as a safety net for a
// future model version whose class map might not be fully populated yet.
//
// Because this is a closed-set softmax classifier, it ALWAYS produces a
// normalized, confident-looking probability distribution — even for input
// that isn't a plant at all (a desk, a wall, a hand, ...). Softmax has no
// concept of "none of the above". Out-of-distribution rejection is handled
// upstream (ValidateImageUseCase, a cheap pre-inference content gate) and
// downstream (the entropy check below, defense-in-depth) — NOT by this
// class's own confidence score, which alone is not a reliable OOD signal.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Result returned by [MlInferenceService.runInference].
class InferenceResult {
  /// Index in CLASS_NAMES of the top predicted class.
  final int topClassIndex;

  /// Softmax probability of the top class (0.0–1.0).
  final double confidence;

  /// Disease ID for the top class, or null for unsupported crops.
  final String? diseaseId;

  /// Whether the predicted crop is in our supported set.
  final bool isSupported;

  /// Top-5 (index, probability) pairs in descending probability order.
  final List<(int, double)> topFive;

  /// Normalized Shannon entropy of the full 38-class softmax distribution,
  /// in [0, 1]. 0 = fully peaked on one class, 1 = uniform/maximally
  /// uncertain. Used as a defense-in-depth OOD signal alongside [confidence]:
  /// a well-formed, in-distribution leaf photo should produce a low-entropy
  /// distribution; an out-of-distribution image that still happens to score
  /// a high top-1 confidence tends to have a less clean/higher-entropy
  /// overall shape than a genuine match.
  final double entropy;

  const InferenceResult({
    required this.topClassIndex,
    required this.confidence,
    required this.diseaseId,
    required this.isSupported,
    required this.topFive,
    required this.entropy,
  });
}

class MlInferenceService {
  static const String _modelAsset =
      'assets/models/cropcare_field_mobilenetv3_fp16.tflite';

  static const int _inputSize = 224;

  // Confidence threshold: results below this → LOW_CONFIDENCE result state.
  // Calibrated 2026-08 (August)-29 against N field images (PlantDoc, held out from
  // training). At this threshold: 85.8% precision, 95.5% coverage.
  // See ml/build_calibration_notebook.py.

  static const double confidenceThreshold = 0.45;

  // Normalized-entropy ceiling: results ABOVE this (i.e. distribution too
  // "spread out" to trust even if top-1 confidence cleared the threshold
  // above) are downgraded to LOW_CONFIDENCE. See [InferenceResult.entropy].
  // Left at 0.50, and that is a decision rather than an oversight: entropy is
  // normalised by log(numClasses), so dropping 38 -> 34 classes barely moves
  // it. Label smoothing raises entropy across the board, which makes this
  // gate fire slightly more often - the safe direction.
  static const double entropyThreshold = 0.50;

  // ── Class index → disease_id mapping ──────────────────────────────────────
  // Maps all 38 PlantVillage output classes to their SQLite disease IDs.
  /// Classes that are insect damage rather than infection.
  ///
  /// A farmer treats a caterpillar differently from a fungus, and the old
  /// model had exactly one arthropod class so the distinction never came up.
  static const Set<int> pestClassIndices = {7, 8, 18};

  static bool isPest(int index) => pestClassIndices.contains(index);

  static const Map<int, String> _classIndexToDiseaseId = {
    0: 'paddy_bacterial_leaf_blight',
    1: 'paddy_bacterial_leaf_streak',
    2: 'paddy_bacterial_panicle_blight',
    3: 'paddy_blast',
    4: 'paddy_brown_spot',
    5: 'paddy_downy_mildew',
    6: 'paddy_tungro',
    7: 'paddy_dead_heart',
    8: 'paddy_hispa',
    9: 'paddy_healthy',
    10: 'tomato_bacterial_spot',
    11: 'tomato_early_blight',
    12: 'tomato_late_blight',
    13: 'tomato_leaf_mold',
    14: 'tomato_septoria_leaf_spot',
    15: 'tomato_target_spot',
    16: 'tomato_yellow_leaf_curl_virus',
    17: 'tomato_mosaic_virus',
    18: 'tomato_spider_mites',
    19: 'tomato_healthy',
    20: 'chili_bacterial_spot',
    21: 'chili_healthy',
    22: 'potato_early_blight',
    23: 'potato_late_blight',
    24: 'potato_healthy',
    25: 'cassava_bacterial_blight',
    26: 'cassava_brown_streak',
    27: 'cassava_green_mottle',
    28: 'cassava_mosaic',
    29: 'cassava_healthy',
    30: 'corn_gray_leaf_spot',
    31: 'corn_common_rust',
    32: 'corn_northern_leaf_blight',
    33: 'corn_healthy',
  };

  static const List<String> _classNames = [
    'paddy_bacterial_leaf_blight',                 // 0
    'paddy_bacterial_leaf_streak',                 // 1
    'paddy_bacterial_panicle_blight',              // 2
    'paddy_blast',                                 // 3
    'paddy_brown_spot',                            // 4
    'paddy_downy_mildew',                          // 5
    'paddy_tungro',                                // 6
    'paddy_dead_heart',                            // 7
    'paddy_hispa',                                 // 8
    'paddy_healthy',                               // 9
    'tomato_bacterial_spot',                       // 10
    'tomato_early_blight',                         // 11
    'tomato_late_blight',                          // 12
    'tomato_leaf_mold',                            // 13
    'tomato_septoria_leaf_spot',                   // 14
    'tomato_target_spot',                          // 15
    'tomato_yellow_leaf_curl_virus',               // 16
    'tomato_mosaic_virus',                         // 17
    'tomato_spider_mites',                         // 18
    'tomato_healthy',                              // 19
    'chili_bacterial_spot',                        // 20
    'chili_healthy',                               // 21
    'potato_early_blight',                         // 22
    'potato_late_blight',                          // 23
    'potato_healthy',                              // 24
    'cassava_bacterial_blight',                    // 25
    'cassava_brown_streak',                        // 26
    'cassava_green_mottle',                        // 27
    'cassava_mosaic',                              // 28
    'cassava_healthy',                             // 29
    'corn_gray_leaf_spot',                         // 30
    'corn_common_rust',                            // 31
    'corn_northern_leaf_blight',                   // 32
    'corn_healthy',                                // 33
  ];

  Interpreter? _interpreter;

  /// Loads the TFLite model from assets. Call once before [runInference].
  Future<void> loadModel() async {
    _interpreter?.close();
    _interpreter = await Interpreter.fromAsset(_modelAsset);
  }

  /// Runs inference on the image at [imageLocalPath].
  ///
  /// Throws [StateError] if [loadModel] has not been called first.
  /// Throws on file I/O or inference errors — callers should catch.
  Future<InferenceResult> runInference(String imageLocalPath) async {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('MlInferenceService: loadModel() must be called before runInference()');
    }

    // 1. Read and preprocess image
    final inputTensor = await _preprocessImage(imageLocalPath);

    // 2. Prepare output buffer: [1, 38] float32
    final outputBuffer = List.filled(1 * _classNames.length, 0.0)
        .reshape([1, _classNames.length]);

    // 3. Run inference
    interpreter.run(inputTensor, outputBuffer);

    // 4. Extract raw logits and apply softmax
    final logits = (outputBuffer[0] as List).cast<double>();
    final probs = _softmax(logits);

    // 5. Find top-5
    final indexed = List.generate(probs.length, (i) => (i, probs[i]));
    indexed.sort((a, b) => b.$2.compareTo(a.$2));
    final topFive = indexed.take(5).toList();

    final topIndex = topFive.first.$1;
    final topConf = topFive.first.$2;
    final diseaseId = _classIndexToDiseaseId[topIndex];

    return InferenceResult(
      topClassIndex: topIndex,
      confidence: topConf,
      diseaseId: diseaseId,
      isSupported: diseaseId != null,
      topFive: topFive,
      entropy: _normalizedEntropy(probs),
    );
  }

  /// Returns the class name string for a given output index.
  static String classNameAt(int index) => _classNames[index];

  /// Returns the `disease` table id for a given output index, or null when the
  /// class is one this app does not carry a disease row for.
  ///
  /// Exposed so callers recording runner-up predictions can store a real
  /// disease id. They previously stored `index.toString()`, which looked like
  /// an id, joined to nothing, and could not be rendered.
  static String? diseaseIdAt(int index) => _classIndexToDiseaseId[index];

  // ---------------------------------------------------------------------------
  // Preprocessing
  // ---------------------------------------------------------------------------

  /// Loads image from disk, resizes to 224×224, normalizes to [0,1].
  /// Returns a [List] shaped [1, 224, 224, 3] (NHWC float32).
  Future<List> _preprocessImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) {
      throw FormatException('MlInferenceService: could not decode image at $path');
    }

    final resized = img.copyResize(decoded, width: _inputSize, height: _inputSize);

    // Build [1, 224, 224, 3] float32 tensor
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    return input;
  }

  // ---------------------------------------------------------------------------
  // Math
  // ---------------------------------------------------------------------------

  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((l) => math.exp(l - maxLogit)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  /// Shannon entropy of [probs], normalized to [0, 1] by dividing by
  /// log(n) (the maximum possible entropy for an n-class uniform
  /// distribution). 0 = one class carries all the probability mass,
  /// 1 = perfectly uniform/uncertain.
  double _normalizedEntropy(List<double> probs) {
    if (probs.length <= 1) return 0;
    double h = 0;
    for (final p in probs) {
      if (p <= 0) continue; // 0 * log(0) := 0
      h -= p * math.log(p);
    }
    final maxH = math.log(probs.length);
    return maxH == 0 ? 0 : (h / maxH).clamp(0.0, 1.0);
  }

  /// Release interpreter resources. Call when the service is no longer needed.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
