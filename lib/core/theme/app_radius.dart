// lib/core/theme/app_radius.dart
//
// Corner-radius scale. diagnosis_result_screen.dart alone previously used
// radii of 8, 10, 12, 14, 16 and 20 across cards and chips in a single
// screen, which is visible as inconsistency even if no one can name it.

import 'package:flutter/widgets.dart';

class AppRadius {
  const AppRadius._();

  /// 8 — inputs, small buttons, inline code/box callouts.
  static const Radius smRadius = Radius.circular(8);
  static const BorderRadius sm = BorderRadius.all(smRadius);

  /// 12 — the default for cards and banners.
  static const Radius mdRadius = Radius.circular(12);
  static const BorderRadius md = BorderRadius.all(mdRadius);

  /// 16 — large/hero cards, bottom sheets.
  static const Radius lgRadius = Radius.circular(16);
  static const BorderRadius lg = BorderRadius.all(lgRadius);

  /// Fully rounded — pills: status chips, filter chips, segmented toggles.
  static const Radius fullRadius = Radius.circular(999);
  static const BorderRadius full = BorderRadius.all(fullRadius);
}
