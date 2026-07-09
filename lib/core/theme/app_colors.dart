import 'dart:ui';

/// OurSpace color palette.
///
/// Raw, feature-agnostic design tokens. Feature code must reference these
/// tokens (or the assembled [ColorScheme]) instead of Material `Colors.*`
/// or hard-coded hex values. Themed component colors are assembled in
/// `AppTheme`.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF5B5BD6);
  static const Color secondary = Color(0xFFFF8E7A);

  // Content placed on top of brand / semantic colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onError = Color(0xFFFFFFFF);

  // Neutral surfaces
  static const Color background = Color(0xFFF8F7F5);
  static const Color surface = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  // Lines and outlines
  static const Color border = Color(0xFFE5E7EB);

  // Semantic
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF22C55E);

  // Overlays
  /// Immersive-media background (full-screen image/video viewers).
  static const Color mediaBackground = Color(0xFF000000);
}
