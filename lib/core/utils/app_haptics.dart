// lib/core/utils/app_haptics.dart
//
// Haptic feedback, gated on the user's accessibility preference.
//
// The "Haptic feedback" toggle existed in the Accessibility screen with no
// consumer anywhere — it controlled nothing. Rather than delete it, it is
// wired here: confirming a shutter press by feel matters when the screen is
// washed out in direct sun, which is the normal condition for this app.
//
// Deliberately sparing. Haptics on every tap is noise; these fire only where
// something irreversible or awaited has happened.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/settings/accessibility_cubit.dart';

class AppHaptics {
  const AppHaptics._();

  static bool _enabled(BuildContext context) {
    try {
      return context.read<AccessibilityCubit>().state.hapticFeedbackEnabled;
    } catch (_) {
      // Not in scope (tests, isolated widgets): stay silent rather than
      // buzzing against a preference we cannot read.
      return false;
    }
  }

  /// A photo was taken.
  static void capture(BuildContext context) {
    if (_enabled(context)) HapticFeedback.mediumImpact();
  }

  /// A result the user was waiting for has arrived.
  static void resultReady(BuildContext context) {
    if (_enabled(context)) HapticFeedback.lightImpact();
  }

  /// Something was rejected or failed.
  static void failure(BuildContext context) {
    if (_enabled(context)) HapticFeedback.heavyImpact();
  }
}
