/// OurSpace spacing scale, based on a 4pt grid.
///
/// Use these constants for all padding, margins and gaps.
/// Never hard-code spacing values in feature code.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Semantic aliases — prefer these where they express intent.

  /// Horizontal padding for screen content.
  static const double screenPadding = md;

  /// Inner padding for cards and tiles.
  static const double cardPadding = md;

  /// Vertical gap between items in a list.
  static const double listGap = sm;

  /// Gap between a form field and the next element.
  static const double fieldGap = md;

  /// Gap between distinct content sections on a screen.
  static const double sectionGap = lg;
}
