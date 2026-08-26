// lib/core/constants/crop_visuals.dart
//
// A distinct icon + accent colour per crop.
//
// Every crop previously rendered with the same generic `Icons.grass`, which
// made the crop list a wall of identical rows — the hardest possible thing to
// scan visually, and actively unhelpful for a user who reads slowly or not at
// all. Distinct shape AND colour per crop gives two non-textual cues.
//
// These are Material glyphs rather than bespoke artwork: there is no icon
// asset pipeline in this project, and inventing one is a separate piece of
// work. The goal here is differentiation, not botanical accuracy.

import 'package:flutter/material.dart';

class CropVisual {
  final IconData icon;
  final Color color;

  const CropVisual(this.icon, this.color);
}

class CropVisuals {
  const CropVisuals._();

  static const CropVisual _fallback =
      CropVisual(Icons.eco_rounded, Color(0xFF2E7D32));

  static const Map<String, CropVisual> _byCropId = {
    'tomato': CropVisual(Icons.local_florist_rounded, Color(0xFFC62828)),
    'chili': CropVisual(Icons.local_fire_department_rounded, Color(0xFFD84315)),
    'potato': CropVisual(Icons.egg_rounded, Color(0xFF8D6E63)),
    'paddy': CropVisual(Icons.grass_rounded, Color(0xFF9E7B0A)),
    'rice': CropVisual(Icons.grass_rounded, Color(0xFF9E7B0A)),
    'corn': CropVisual(Icons.grain_rounded, Color(0xFFF9A825)),
    'apple': CropVisual(Icons.apple_rounded, Color(0xFFC2185B)),
    'grape': CropVisual(Icons.bubble_chart_rounded, Color(0xFF6A1B9A)),
    'orange': CropVisual(Icons.brightness_1_rounded, Color(0xFFEF6C00)),
    'peach': CropVisual(Icons.circle_rounded, Color(0xFFEF9A9A)),
    'cherry': CropVisual(Icons.circle_rounded, Color(0xFFB71C1C)),
    'strawberry': CropVisual(Icons.spa_rounded, Color(0xFFD81B60)),
    'raspberry': CropVisual(Icons.spa_rounded, Color(0xFFAD1457)),
    'blueberry': CropVisual(Icons.circle_rounded, Color(0xFF1565C0)),
    'soybean': CropVisual(Icons.scatter_plot_rounded, Color(0xFF558B2F)),
    'squash': CropVisual(Icons.sports_rugby_rounded, Color(0xFFEF6C00)),
    'pepper': CropVisual(Icons.local_fire_department_rounded, Color(0xFFD84315)),
  };

  /// Visual for [cropId], falling back to a generic leaf for anything
  /// unrecognised (including the `unknown` crop used before inference has
  /// derived one).
  static CropVisual forCrop(String? cropId) {
    if (cropId == null) return _fallback;
    return _byCropId[cropId.toLowerCase()] ?? _fallback;
  }
}
