// lib/data/local/ml/ml_inference_service.dart
//
// On-device TFLite inference using tflite_flutter ^0.12.0.
//
// Model: plant_disease_mobilenetv2_float32.tflite
//   - Input:  [1, 224, 224, 3]  float32  NHWC  (onnx2tf converts NCHW→NHWC)
//   - Output: [1, 38]           float32  raw logits (NOT softmax)
//   - Preprocessing: resize to 224×224, normalize to [0,1] (divide by 255)
//
// CLASS_NAMES order matches the 38-element output vector.
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
      'assets/models/plant_disease_mobilenetv2.tflite';

  static const int _inputSize = 224;

  // Confidence threshold: results below this → LOW_CONFIDENCE result state.
  static const double confidenceThreshold = 0.60;

  // Normalized-entropy ceiling: results ABOVE this (i.e. distribution too
  // "spread out" to trust even if top-1 confidence cleared the threshold
  // above) are downgraded to LOW_CONFIDENCE. See [InferenceResult.entropy].
  static const double entropyThreshold = 0.50;

  // ── Class index → disease_id mapping ──────────────────────────────────────
  // Maps all 38 PlantVillage output classes to their SQLite disease IDs.
  static const Map<int, String> _classIndexToDiseaseId = {
    0: 'apple_scab',
    1: 'apple_black_rot',
    2: 'apple_cedar_rust',
    3: 'apple_healthy',
    4: 'blueberry_healthy',
    5: 'cherry_powdery_mildew',
    6: 'cherry_healthy',
    7: 'corn_gray_leaf_spot',
    8: 'corn_common_rust',
    9: 'corn_northern_leaf_blight',
    10: 'corn_healthy',
    11: 'grape_black_rot',
    12: 'grape_black_measles',
    13: 'grape_leaf_blight',
    14: 'grape_healthy',
    15: 'orange_citrus_greening',
    16: 'peach_bacterial_spot',
    17: 'peach_healthy',
    18: 'chili_bacterial_spot',
    19: 'chili_healthy',
    20: 'potato_early_blight',
    21: 'potato_late_blight',
    22: 'potato_healthy',
    23: 'raspberry_healthy',
    24: 'soybean_healthy',
    25: 'squash_powdery_mildew',
    26: 'strawberry_leaf_scorch',
    27: 'strawberry_healthy',
    28: 'tomato_bacterial_spot',
    29: 'tomato_early_blight',
    30: 'tomato_late_blight',
    31: 'tomato_leaf_mold',
    32: 'tomato_septoria_leaf_spot',
    33: 'tomato_spider_mites',
    34: 'tomato_target_spot',
    35: 'tomato_yellow_leaf_curl_virus',
    36: 'tomato_mosaic_virus',
    37: 'tomato_healthy',
  };

  static const List<String> _classNames = [
    'Apple___Apple_scab',                                        // 0
    'Apple___Black_rot',                                         // 1
    'Apple___Cedar_apple_rust',                                  // 2
    'Apple___healthy',                                           // 3
    'Blueberry___healthy',                                       // 4
    'Cherry_(including_sour)___Powdery_mildew',                  // 5
    'Cherry_(including_sour)___healthy',                         // 6
    'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot',        // 7
    'Corn_(maize)___Common_rust_',                               // 8
    'Corn_(maize)___Northern_Leaf_Blight',                       // 9
    'Corn_(maize)___healthy',                                    // 10
    'Grape___Black_rot',                                         // 11
    'Grape___Esca_(Black_Measles)',                              // 12
    'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)',                // 13
    'Grape___healthy',                                           // 14
    'Orange___Haunglongbing_(Citrus_greening)',                   // 15
    'Peach___Bacterial_spot',                                    // 16
    'Peach___healthy',                                           // 17
    'Pepper,_bell___Bacterial_spot',                             // 18 → chili
    'Pepper,_bell___healthy',                                    // 19 → chili
    'Potato___Early_blight',                                     // 20
    'Potato___Late_blight',                                      // 21
    'Potato___healthy',                                          // 22
    'Raspberry___healthy',                                       // 23
    'Soybean___healthy',                                         // 24
    'Squash___Powdery_mildew',                                   // 25
    'Strawberry___Leaf_scorch',                                  // 26
    'Strawberry___healthy',                                      // 27
    'Tomato___Bacterial_spot',                                   // 28
    'Tomato___Early_blight',                                     // 29
    'Tomato___Late_blight',                                      // 30
    'Tomato___Leaf_Mold',                                        // 31
    'Tomato___Septoria_leaf_spot',                               // 32
    'Tomato___Spider_mites Two-spotted_spider_mite',             // 33
    'Tomato___Target_Spot',                                      // 34
    'Tomato___Tomato_Yellow_Leaf_Curl_Virus',                    // 35
    'Tomato___Tomato_mosaic_virus',                              // 36
    'Tomato___healthy',                                          // 37
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
