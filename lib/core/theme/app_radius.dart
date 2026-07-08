import 'package:flutter/painting.dart';

/// OurSpace border radius scale.
///
/// Generous rounding keeps the interface soft and calm. Use the prebuilt
/// [BorderRadius] constants where possible; raw doubles are exposed for
/// cases that need a custom [Radius].
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  /// Effectively circular; pills and fully rounded containers.
  static const double full = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));
}
