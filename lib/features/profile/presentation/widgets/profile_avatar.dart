import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Circular avatar with cached network photo, initials fallback, an
/// optional edit badge, upload-progress overlay and optional Hero tag
/// (pairs with the app-wide full-screen image viewer).
///
/// Behavior is caller-defined via [onTap]: the user's own profile opens
/// an actions sheet; other users' profiles open the viewer directly.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.photoUrl,
    this.displayName,
    this.radius = 48,
    this.onTap,
    this.showEditBadge = false,
    this.uploading = false,
    this.heroTag,
  });

  final String? photoUrl;
  final String? displayName;
  final double radius;

  /// Invoked when the avatar (or its edit badge) is tapped.
  final VoidCallback? onTap;

  /// Shows the camera badge; enable on the user's own editable profile.
  final bool showEditBadge;

  final bool uploading;

  /// Set to the same tag as the destination viewer for a Hero flight.
  /// Leave null when several avatars of the same user can be on screen
  /// simultaneously (duplicate Hero tags are not allowed).
  final Object? heroTag;

  String get _initials {
    final source = (displayName ?? '').trim();
    if (source.isEmpty) return '?';
    final parts = source.split(RegExp(r'\s+'));
    final first = parts.first.characters.first;
    final second = parts.length > 1 ? parts.last.characters.first : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      foregroundImage:
          photoUrl == null ? null : CachedNetworkImageProvider(photoUrl!),
      child: Text(
        _initials,
        style: AppTypography.title.copyWith(
          color: AppColors.primary,
          fontSize: radius * 0.7,
        ),
      ),
    );
    if (heroTag != null) {
      avatar = Hero(tag: heroTag!, child: avatar);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(onTap: uploading ? null : onTap, child: avatar),
        if (uploading)
          SizedBox(
            width: radius * 0.75,
            height: radius * 0.75,
            child: const CircularProgressIndicator(strokeWidth: 2.5),
          ),
        if (showEditBadge && !uploading)
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Icon(
                    Icons.photo_camera_outlined,
                    size: radius >= 32 ? AppIcons.sm : AppIcons.xs,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
