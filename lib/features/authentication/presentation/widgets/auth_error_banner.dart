import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Inline error area for authentication forms.
///
/// Renders nothing when [message] is null; animates size changes so the
/// form settles gently instead of jumping.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppDurations.medium,
      curve: AppCurves.gentle,
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: AppRadius.mdAll,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: AppIcons.sm,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      message!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
