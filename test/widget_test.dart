import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ourspace_app/core/services/app_startup.dart';
import 'package:ourspace_app/main.dart';

/// No-op startup so widget tests never touch real Firebase.
class _FakeAppStartup extends AppStartup {
  @override
  Future<void> initialize() async {}
}

Widget _buildApp() {
  return ProviderScope(
    overrides: [
      appStartupProvider.overrideWithValue(_FakeAppStartup()),
    ],
    child: const OurSpaceApp(),
  );
}

void main() {
  testWidgets('app launches into the splash screen', (tester) async {
    await tester.pumpWidget(_buildApp());

    expect(find.text('OurSpace'), findsOneWidget);
    expect(
      find.text('Private spaces for people who matter.'),
      findsOneWidget,
    );

    // Drain the pending minimum-duration timer so the test ends cleanly.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets('splash navigates to login after the minimum duration',
      (tester) async {
    await tester.pumpWidget(_buildApp());

    // Let the splash fade-in finish.
    await tester.pump(const Duration(milliseconds: 600));

    // Advance past the 1-second minimum splash duration.
    await tester.pump(const Duration(seconds: 1));

    // Complete the route transition to login.
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Private spaces for people who matter.'), findsNothing);
  });
}
