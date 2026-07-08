import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/domain/entities/app_user.dart';
import '../../features/authentication/presentation/pages/forgot_password_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/authentication/presentation/providers/auth_providers.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'app_routes.dart';

/// Application router and navigation policy.
///
/// The authentication session (`authStateChangesProvider`) is the single
/// source of truth: every auth-based navigation decision is made in
/// [GoRouter.redirect]. Pages never navigate between Splash, Login and
/// Home themselves.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Mirrors the session stream into a Listenable for GoRouter.
  //
  // A normal (non-weak) listener guarantees delivery of every session
  // state. It initializes the provider eagerly, which is safe: the
  // provider gates itself on app startup before touching Firebase.
  final session = ValueNotifier<AsyncValue<AppUser?>>(
    const AsyncValue.loading(),
  );
  ref.onDispose(session.dispose);
  ref.listen(
    authStateChangesProvider,
    (previous, next) => session.value = next,
    fireImmediately: true,
  );

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: session,
    redirect: (context, state) {
      final location = state.matchedLocation;

      // The splash owns its own exit: it yields control with a single
      // handoff navigation once startup and the first session value are
      // ready. Never redirect it — early session emissions must not cut
      // the brand moment short.
      if (location == AppRoutes.splash) return null;

      final auth = session.value;

      // Session unknown (still resolving, or startup failed): back to
      // the splash, which shows progress or its retry state.
      final unresolved = auth.isLoading || (auth.hasError && !auth.hasValue);
      if (unresolved) return AppRoutes.splash;

      // Riverpod 3: `AsyncValue.value` is nullable (null while loading or
      // on error without a previous value) — the old `valueOrNull`.
      final signedIn = auth.value != null;
      final onAuthPages = location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.forgotPassword;

      if (signedIn) return onAuthPages ? AppRoutes.home : null;
      return onAuthPages ? null : AppRoutes.login;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRoutes.registerName,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: AppRoutes.forgotPasswordName,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.homeName,
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
});
