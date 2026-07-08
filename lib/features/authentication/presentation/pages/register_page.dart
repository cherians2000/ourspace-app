import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/validators/email_validator.dart';
import '../../../../core/utils/validators/password_validator.dart';
import '../../../../core/utils/validators/required_validator.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_error_message.dart';
import '../widgets/auth_text_field.dart';

/// Account creation.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // Note: the name is UI-only for now; it is persisted during Firestore
    // profile creation in a later task.
    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
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
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final error =
        authState.status == AuthStatus.failure ? authState.error : null;

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
                  Text(
                    'Create your account',
                    style: AppTypography.headline.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'A private space for the people who matter.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  AuthErrorBanner(message: error?.userMessage),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AuthTextField(
                          controller: _nameController,
                          label: 'Name',
                          hint: 'How should we call you?',
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          validator: (value) => RequiredValidator.validate(
                            value,
                            message: 'Please enter your name.',
                          ),
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: AppSpacing.fieldGap),
                        AuthTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: EmailValidator.validate,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: AppSpacing.fieldGap),
                        AuthTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'At least ${PasswordValidator.minLength} characters',
                          obscurable: true,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: PasswordValidator.validate,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: AppSpacing.fieldGap),
                        AuthTextField(
                          controller: _confirmController,
                          label: 'Confirm password',
                          obscurable: true,
                          textInputAction: TextInputAction.done,
                          validator: (value) =>
                              PasswordValidator.validateConfirmation(
                            value,
                            _passwordController.text,
                          ),
                          enabled: !isLoading,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ],
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
                        : const Text('Create account'),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: isLoading ? null : _backToLogin,
                        child: const Text('Log in'),
                      ),
                    ],
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
