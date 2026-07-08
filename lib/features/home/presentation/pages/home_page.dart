import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../authentication/presentation/providers/auth_state.dart';

/// Placeholder home screen.
///
/// Will list the user's Spaces once the Spaces feature lands.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isLoading =
        ref.watch(authNotifierProvider).status == AuthStatus.loading;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Home', style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Coming soon',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            // TEMPORARY(auth-testing): sign-out button to exercise the
            // session-driven redirect. Remove when the real Home UI lands.
            OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => ref.read(authNotifierProvider.notifier).signOut(),
              icon: const Icon(Icons.logout, size: AppIcons.sm),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
