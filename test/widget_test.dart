import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ourspace_app/core/services/app_startup.dart';
import 'package:ourspace_app/features/authentication/presentation/pages/login_page.dart';
import 'package:ourspace_app/features/authentication/presentation/providers/auth_providers.dart';
import 'package:ourspace_app/features/splash/presentation/pages/splash_page.dart';
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
      // Signed-out session; keeps tests off real Firebase.
      authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
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

    // Drain the splash minimum-duration timer and settle the handoff
    // navigation so the test ends cleanly.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets('splash navigates to login after the minimum duration',
      (tester) async {
    await tester.pumpWidget(_buildApp());

    // Let the splash fade-in finish, advance past the 1-second minimum
    // splash duration (the session override emits immediately), then
    // settle the handoff navigation and redirect to login.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Assert on page types, not display copy: marketing text may change,
    // the page classes are stable.
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(SplashPage), findsNothing);
  });
}
