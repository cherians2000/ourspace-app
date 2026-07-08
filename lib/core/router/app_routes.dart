/// Route paths and names for the application.
///
/// Features navigate using these constants (e.g. `context.go(AppRoutes.login)`)
/// so paths are never hard-coded at call sites.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String splashName = 'splash';

  static const String login = '/login';
  static const String loginName = 'login';

  static const String register = '/register';
  static const String registerName = 'register';

  static const String forgotPassword = '/forgot-password';
  static const String forgotPasswordName = 'forgotPassword';

  static const String home = '/home';
  static const String homeName = 'home';
}
