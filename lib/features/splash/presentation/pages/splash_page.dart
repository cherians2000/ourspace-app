import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/services/app_startup.dart';
import '../../../../core/theme/theme.dart';

/// Branded launch screen.
///
/// Runs application startup (Firebase initialization) while showing the
/// OurSpace identity for at least [_minimumDuration], so the brand moment
/// never flashes by. Navigates to login when both have completed.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  /// The splash stays visible at least this long, even if startup finishes
  /// sooner.
  static const Duration _minimumDuration = Duration(seconds: 1);

  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Runs startup work and the minimum display time in parallel, then
  /// navigates. Navigation waits for whichever finishes last.
  Future<void> _bootstrap() async {
    try {
      await Future.wait([
        Future<void>.delayed(_minimumDuration),
        ref.read(appStartupProvider).initialize(),
      ]);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  void _retry() {
    setState(() => _failed = false);
    _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedSwitcher(
          duration: AppDurations.medium,
          switchInCurve: AppCurves.gentle,
          switchOutCurve: AppCurves.gentle,
          child: _failed ? _buildError() : _buildBrand(),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('splash-brand'),
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
            style: AppTypography.display.copyWith(color: AppColors.primary),
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
    );
  }

  Widget _buildError() {
    return Padding(
      key: const ValueKey('splash-error'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.textSecondary,
            size: AppIcons.lg,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            "Couldn't start OurSpace",
            style: AppTypography.title.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: _retry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
