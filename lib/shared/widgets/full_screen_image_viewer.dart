import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// App-wide full-screen image viewer.
///
/// The single implementation for viewing any image immersively (profile
/// photos, chat images, future posts). Features: black background,
/// pinch-to-zoom and pan, optional Hero transition, dismiss by tapping
/// outside the image or pressing Back.
///
/// Open it with [show]; do not build separate viewers per feature.
class FullScreenImageViewer extends StatelessWidget {
  const FullScreenImageViewer({
    super.key,
    required this.image,
    this.heroTag,
  });

  final ImageProvider image;

  /// Matches the tag on the source widget for a smooth open/close flight.
  final Object? heroTag;

  /// Pushes the viewer as a transparent fade route on the root navigator,
  /// so it overlays everything (including nested navigators later).
  static Future<void> show(
    BuildContext context, {
    required ImageProvider image,
    Object? heroTag,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: AppDurations.medium,
        reverseTransitionDuration: AppDurations.medium,
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenImageViewer(image: image, heroTag: heroTag),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget picture = Image(
      image: image,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator()),
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.broken_image_outlined,
        color: AppColors.textSecondary,
        size: AppIcons.xl,
      ),
    );
    if (heroTag != null) {
      picture = Hero(tag: heroTag!, child: picture);
    }

    return Scaffold(
      backgroundColor: AppColors.mediaBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Tap anywhere outside the image to close. The image area sits
          // on top, so zoom/pan gestures are unaffected.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
          ),
          Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              clipBehavior: Clip.none,
              child: picture,
            ),
          ),
        ],
      ),
    );
  }
}
