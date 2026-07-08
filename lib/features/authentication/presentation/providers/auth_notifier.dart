import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_state.dart';

/// Orchestrates authentication actions and exposes [AuthState] to the UI.
///
/// Method bodies are intentionally empty skeletons; they are implemented
/// together with the Firebase Auth integration, by calling the domain use
/// cases through `ref`.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> signIn({required String email, required String password}) async {
    // TODO(auth): implement with the SignIn use case.
  }

  Future<void> signUp({required String email, required String password}) async {
    // TODO(auth): implement with the SignUp use case.
  }

  Future<void> signOut() async {
    // TODO(auth): implement with the SignOut use case.
  }

  Future<void> forgotPassword({required String email}) async {
    // TODO(auth): implement with the ForgotPassword use case.
  }
}
