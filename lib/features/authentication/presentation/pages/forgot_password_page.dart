import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/validators/email_validator.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_error_message.dart';
import '../widgets/auth_text_field.dart';

/// Password reset via email.
///
/// Success is tracked locally (page-level), by design: sending a reset
/// email does not change authentication state.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.forgotPassword(email: _emailController.text.trim());

    if (!mounted) return;
    final failed =
        ref.read(authNotifierProvider).status == AuthStatus.failure;
    if (!failed) setState(() => _emailSent = true);
  }

  void _backToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AnimatedSwitcher(
                duration: AppDurations.medium,
                switchInCurve: AppCurves.gentle,
                switchOutCurve: AppCurves.gentle,
                child: _emailSent ? _buildSuccess() : _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final error =
        authState.status == AuthStatus.failure ? authState.error : null;

    return Column(
      key: const ValueKey('forgot-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Forgot your password?',
          style: AppTypography.headline.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "Enter your email and we'll send you a link to reset it.",
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AuthErrorBanner(message: error?.userMessage),
        Form(
          key: _formKey,
          child: AuthTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: EmailValidator.validate,
            enabled: !isLoading,
            onFieldSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox(
                  width: AppIcons.sm,
                  height: AppIcons.sm,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send reset email'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: isLoading ? null : _backToLogin,
          child: const Text('Back to login'),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('forgot-success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          color: AppColors.success,
          size: AppIcons.xl,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Reset link sent',
          textAlign: TextAlign.center,
          style: AppTypography.headline.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Check ${_emailController.text.trim()} for a link to reset '
          'your password. It may take a minute to arrive.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        OutlinedButton(
          onPressed: _backToLogin,
          child: const Text('Back to login'),
        ),
      ],
    );
  }
}
