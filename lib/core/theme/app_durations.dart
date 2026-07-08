import 'package:flutter/animation.dart';

/// OurSpace animation durations.
///
/// Predictable, consistent motion keeps the app feeling calm.
/// Use these for all implicit/explicit animations and transitions.
abstract final class AppDurations {
  /// Micro-interactions: taps, state changes, ripples.
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard transitions: page changes, expansions, reveals.
  static const Duration medium = Duration(milliseconds: 300);

  /// Ambient changes: fades of large surfaces, subtle emphasis.
  static const Duration slow = Duration(milliseconds: 500);
}

/// Standard curves paired with [AppDurations].
abstract final class AppCurves {
  /// Default for most animations.
  static const Curve standard = Curves.easeOutCubic;

  /// For elements entering and leaving the screen together.
  static const Curve emphasized = Curves.easeInOutCubic;

  /// For content that fades in place.
  static const Curve gentle = Curves.easeInOut;
}
