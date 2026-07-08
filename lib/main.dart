import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/theme.dart';

void main() {
  runApp(const ProviderScope(child: OurSpaceApp()));
}

/// Root widget of the OurSpace application.
class OurSpaceApp extends ConsumerWidget {
  const OurSpaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'OurSpace',
      theme: AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
