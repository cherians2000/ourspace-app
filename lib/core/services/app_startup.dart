import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';

/// Performs one-time application startup work.
///
/// Every bootstrap step lives in [_runStartup] so new services (crash
/// reporting, presence warm-up, remote config, ...) can be added here
/// without touching the splash flow.
class AppStartup {
  AppStartup();

  /// In-flight or completed startup work. Ensures [initialize] is
  /// idempotent: concurrent and repeated calls share a single run.
  Future<void>? _initialization;

  Future<void> initialize() {
    return _initialization ??= _runStartup();
  }

  Future<void> _runStartup() async {
    try {
      // Guards against a second core initialization (e.g. hot restart,
      // or a second AppStartup instance).
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      // Future startup steps are awaited here, after Firebase core.
    } catch (_) {
      // Clear the cached run so a retry can attempt startup again.
      _initialization = null;
      rethrow;
    }
  }
}

/// Startup service, overridable in tests with a fake implementation.
final appStartupProvider = Provider<AppStartup>((ref) => AppStartup());
