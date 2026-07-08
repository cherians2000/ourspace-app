import 'package:flutter/painting.dart';

/// OurSpace type scale.
///
/// Styles define size, weight, letter spacing and line height only.
/// Colors are applied by `AppTheme` (or explicitly at the call site) so
/// each style can be reused on any surface.
///
/// V1 uses the platform system font; no `fontFamily` is set.
abstract final class AppTypography {
  /// Large expressive text: welcome message, empty states.
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.5,
  );

  /// Screen headings.
  static const TextStyle headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.25,
  );

  /// Section and card titles, app bar titles.
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Default reading text.
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Secondary reading text, list subtitles.
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  /// Buttons, form labels, emphasized metadata.
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Timestamps, helper text, fine print.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: 0.2,
  );
}
