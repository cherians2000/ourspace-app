import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/app_user.dart';
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

  /// Establishes the canonical Firestore profile for a freshly
  /// authenticated session (idempotent create-or-refresh).
  ///
  /// Fire-and-forget by design: authentication is the source of identity
  /// and must never depend on Firestore, so profile failures are logged
  /// and never surface into [AuthState].
  void _establishProfile(AppUser user) {
    unawaited(() async {
      try {
        await ref.read(ensureUserProfileProvider)(user);
      } catch (e, stackTrace) {
        developer.log(
          'Profile sync failed for ${user.id}',
          name: 'AuthNotifier',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }());
  }

  /// Clears a visible failure (user edited a field, retried, or returned
  /// to the page), so stale error banners never outlive their context.
  void clearError() {
    if (state.status == AuthStatus.failure) {
      state = const AuthState();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final user = await ref.read(signInProvider)(
        email: email,
        password: password,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
      _establishProfile(user);
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.failure, error: e);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final user = await ref.read(signUpProvider)(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        // Registration sends the first verification email immediately.
        verificationEmailSentAt: DateTime.now(),
      );
      _establishProfile(user);
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.failure, error: e);
    }
  }

  Future<void> signInWithGoogle() async {
    final previous = state;
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final user = await ref.read(signInWithGoogleProvider)();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      _establishProfile(user);
    } on AuthException catch (e) {
      if (e.reason == AuthErrorReason.cancelled) {
        // Dismissing the account picker is not a failure; return quietly.
        state = previous.copyWith(error: null);
      } else {
        state = AuthState(status: AuthStatus.failure, error: e);
      }
    }
  }

  /// Re-sends the verification email. Does not change who is signed in.
  Future<void> sendEmailVerification() async {
    final previous = state;
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      await ref.read(sendEmailVerificationProvider)();
      state = previous.copyWith(
        error: null,
        verificationEmailSentAt: DateTime.now(),
      );
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.failure, error: e);
    }
  }

  /// Re-fetches the current user (e.g. to pick up email verification).
  /// Session-level effects propagate via the auth stream; this only
  /// refreshes the action-state snapshot.
  Future<void> refreshUser() async {
    final previousUser = state.user;
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final user = await ref.read(reloadCurrentUserProvider)();
      // copyWith preserves verificationEmailSentAt, keeping the verify
      // screen's resend cooldown intact across "check again" taps.
      state = user == null
          ? const AuthState(status: AuthStatus.unauthenticated)
          : state.copyWith(
              status: AuthStatus.authenticated,
              user: user,
              error: null,
            );
      // Mirror a newly-verified email into the Firestore profile.
      // FirebaseAuth is the source of truth; the profile copy is for
      // display/queries. Guarded so the write happens only when the
      // value actually flipped.
      if (user != null &&
          user.emailVerified &&
          previousUser?.emailVerified != true) {
        _syncEmailVerifiedMirror(user);
      }
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.failure, error: e);
    }
  }

  /// Fire-and-forget: a failed mirror write must never affect the
  /// verification flow (it self-heals at the next session start anyway).
  void _syncEmailVerifiedMirror(AppUser user) {
    unawaited(() async {
      try {
        await ref.read(syncEmailVerifiedProvider)(
          uid: user.id,
          emailVerified: user.emailVerified,
        );
      } catch (e, stackTrace) {
        developer.log(
          'emailVerified mirror sync failed for ${user.id}',
          name: 'AuthNotifier',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }());
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
