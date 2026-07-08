import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/exceptions/auth_exception.dart';
import 'auth_providers.dart';
import 'auth_state.dart';

/// Orchestrates authentication actions and exposes [AuthState] to the UI.
///
/// All work is delegated to domain use cases; expected failures arrive as
/// [AuthException] and are surfaced through [AuthState.error].
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final user = await ref.read(signInProvider)(
        email: email,
        password: password,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.failure, error: e);
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final user = await ref.read(signUpProvider)(
        email: email,
        password: password,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.failure, error: e);
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      await ref.read(signOutProvider)();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.failure, error: e);
    }
  }

  Future<void> forgotPassword({required String email}) async {
    final previous = state;
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      await ref.read(forgotPasswordProvider)(email: email);
      // Sending a reset email does not change who is signed in.
      state = previous.copyWith(error: null);
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.failure, error: e);
    }
  }
}
