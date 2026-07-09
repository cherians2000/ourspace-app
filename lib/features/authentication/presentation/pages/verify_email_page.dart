import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_error_message.dart';

/// Shown to signed-in users whose email is not yet verified.
///
/// The router keeps unverified users here; once verification is picked up
/// (via refresh → session stream re-emission), the redirect moves on to
/// Home automatically.
class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  /// Resend cooldown, guarding against Firebase's rate limiting.
  static const int _cooldownSeconds = 30;

  Timer? _cooldownTimer;
  int _cooldownRemaining = 0;
  bool _checkedStillUnverified = false;

  @override
  void initState() {
    super.initState();
    // A failure from another auth page must not greet the user here.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(authNotifierProvider.notifier).clearError(),
    );
    // Cooldown only when an email actually went out recently (sign-up
    // sends one automatically; resends record it too). An existing
    // unverified user who just logged in gets an enabled Resend button
    // and no confirmation banner — nothing was sent on their behalf.
    final sentAt =
        ref.read(authNotifierProvider).verificationEmailSentAt;
    if (sentAt != null) {
      final elapsed = DateTime.now().difference(sentAt).inSeconds;
      final remaining = _cooldownSeconds - elapsed;
      if (remaining > 0) _startCooldown(remaining);
    }
  }

  void _startCooldown(int seconds) {
    _cooldownRemaining = seconds;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownRemaining -= 1;
        if (_cooldownRemaining <= 0) timer.cancel();
      });
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    // The resend outcome supersedes any previous status hint.
    setState(() => _checkedStillUnverified = false);
    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.sendEmailVerification();
    if (!mounted) return;
    if (ref.read(authNotifierProvider).status != AuthStatus.failure) {
      setState(() => _startCooldown(_cooldownSeconds));
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _checkedStillUnverified = false);
    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.refreshUser();
    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    final stillUnverified = state.status == AuthStatus.authenticated &&
        !(state.user?.emailVerified ?? false);
    if (stillUnverified) {
      setState(() => _checkedStillUnverified = true);
    }
    // If verification succeeded, the refreshed token re-emits on the
    // session stream and the router redirects to Home — nothing to do.
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final error =
        authState.status == AuthStatus.failure ? authState.error : null;

    // The session stream is the source of truth for who is signed in.
    final email = ref.watch(authStateChangesProvider).value?.email;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.mark_email_unread_outlined,
                    color: AppColors.primary,
                    size: AppIcons.xl,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Verify your email',
                    textAlign: TextAlign.center,
                    style: AppTypography.headline.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'We sent a verification link to '
                    '${email ?? 'your email address'}. '
                    'Open it, then come back here.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  AuthErrorBanner(message: error?.userMessage),
                  if (_cooldownRemaining > 0 && error == null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: AppRadius.mdAll,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.mark_email_read_outlined,
                            color: AppColors.primary,
                            size: AppIcons.sm,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              "We've sent a verification email to your "
                              'inbox.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_checkedStillUnverified)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        'Not verified yet. It can take a minute — check '
                        'your spam folder too.',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: isLoading ? null : _checkVerification,
                    child: isLoading
                        ? const SizedBox(
                            width: AppIcons.sm,
                            height: AppIcons.sm,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("I've verified my email"),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: isLoading || _cooldownRemaining > 0
                        ? null
                        : _resend,
                    child: Text(
                      _cooldownRemaining > 0
                          ? 'Resend email (${_cooldownRemaining}s)'
                          : 'Resend email',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () =>
                            ref.read(authNotifierProvider.notifier).signOut(),
                    child: const Text('Use a different account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
