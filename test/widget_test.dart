import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ourspace_app/core/services/app_startup.dart';
import 'package:ourspace_app/features/authentication/presentation/pages/login_page.dart';
import 'package:ourspace_app/features/authentication/presentation/providers/auth_providers.dart';
import 'package:ourspace_app/features/splash/presentation/pages/splash_page.dart';
import 'package:ourspace_app/main.dart';

/// Must cover `SplashPage._minimumDuration` (currently 2 seconds).
///
/// The production constant is deliberately private, so this mirrors it
/// with headroom instead of importing it. If the splash duration is ever
/// raised above this value, tests will fail with a pending-timer error —
/// update this constant to match.
const Duration _splashDrainDuration = Duration(seconds: 3);

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

/// Advances past the splash minimum duration and settles the handoff
/// navigation, leaving no pending timers behind.
Future<void> _drainSplash(WidgetTester tester) async {
  await tester.pump(_splashDrainDuration);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('app launches into the splash screen', (tester) async {
    await tester.pumpWidget(_buildApp());

    expect(find.text('OurSpace'), findsOneWidget);
    expect(
      find.text('Private spaces for people who matter.'),
      findsOneWidget,
    );

    await _drainSplash(tester);
  });

  testWidgets('splash navigates to login after the minimum duration',
      (tester) async {
    await tester.pumpWidget(_buildApp());

    // Before the minimum duration elapses, the app must still be on the
    // splash — this guards the brand moment against regressions.
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);

    await _drainSplash(tester);

    // Assert on page types, not display copy: marketing text may change,
    // the page classes are stable.
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(SplashPage), findsNothing);
  });
}
