import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme.dart';

/// Branded launch screen.
///
/// Shown while the app starts up, for at least [_minimumDuration] so the
/// brand moment never flashes by. Navigates to login when both the minimum
/// duration and startup work have completed.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  /// The splash stays visible at least this long, even if startup finishes
  /// sooner.
  static const Duration _minimumDuration = Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Runs startup work and the minimum display time in parallel, then
  /// navigates. Navigation waits for whichever finishes last.
  Future<void> _bootstrap() async {
    await Future.wait([
      Future<void>.delayed(_minimumDuration),
      _initializeApp(),
    ]);
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  /// Startup work placeholder.
  ///
  /// Firebase initialization will replace this body later; the splash flow
  /// and minimum-duration handling will not need to change.
  Future<void> _initializeApp() async {
    // Intentionally empty for now.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AppDurations.slow,
          curve: AppCurves.gentle,
          builder: (context, opacity, child) =>
              Opacity(opacity: opacity, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite,
                color: AppColors.secondary,
                size: AppIcons.xl,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'OurSpace',
                style: AppTypography.display.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Private spaces for people who matter.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
