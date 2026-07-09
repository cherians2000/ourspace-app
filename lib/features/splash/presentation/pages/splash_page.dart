import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/services/app_startup.dart';
import '../../../../core/theme/theme.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

/// Branded launch screen.
///
/// Owns application startup and its own display timing: it initializes,
/// waits for at least [_minimumDuration] and the first authentication
/// session value, then yields control with a single handoff navigation.
/// The destination is decided entirely by the router redirect (which
/// rewrites the handoff to Home when a session exists).
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  /// The splash stays visible at least this long, even if startup finishes
  /// sooner.
  static const Duration _minimumDuration = Duration(seconds: 2);

  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Runs startup work and the minimum display time in parallel, waits
  /// for the session to resolve, then hands control to the router.
  Future<void> _bootstrap() async {
    try {
      await Future.wait([
        Future<void>.delayed(_minimumDuration),
        ref.read(appStartupProvider).initialize(),
      ]);
      final session = await ref.read(authStateChangesProvider.future);
      if (session != null) {
        // A restored session is a session establishment: refresh the
        // canonical profile. Fire-and-forget — profile sync must never
        // block or fail app startup.
        unawaited(() async {
          try {
            await ref.read(ensureUserProfileProvider)(session);
          } catch (e, stackTrace) {
            developer.log(
              'Profile sync failed for ${session.id}',
              name: 'SplashPage',
              error: e,
              stackTrace: stackTrace,
            );
          }
        }());
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) return;
    // Handoff, not a destination decision: the router redirect has the
    // final word and rewrites this to Home when signed in.
    context.go(AppRoutes.login);
  }

  void _retry() {
    setState(() => _failed = false);
    // A failed session provider caches its error; rebuild it so startup
    // and the session subscription are attempted again.
    ref.invalidate(authStateChangesProvider);
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
