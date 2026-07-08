import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Placeholder login screen.
///
/// The real authentication UI arrives with the Firebase integration.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Login', style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Coming soon',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
