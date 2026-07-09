import '../entities/app_user.dart';

/// Contract for authentication operations.
///
/// Implementations live in the data layer and must surface expected
/// failures as `AuthException`.
abstract interface class AuthenticationRepository {
  Future<AppUser> signIn({required String email, required String password});

  /// Registers a new account, sets the display name when provided, and
  /// sends a verification email immediately.
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<AppUser> signInWithGoogle();

  /// Re-sends the verification email to the current user.
  Future<void> sendEmailVerification();

  /// Re-fetches the current user from the server (e.g. to pick up a
  /// changed verification status). Returns `null` when signed out.
  Future<AppUser?> reloadCurrentUser();

  Future<void> signOut();

  /// Permanently deletes the current Firebase Authentication account.
  /// Fails with `AuthErrorReason.requiresRecentLogin` when Firebase
  /// demands re-authentication first.
  Future<void> deleteAccount();

  /// Whether Firebase will demand a recent login for security-sensitive
  /// operations (account deletion). Checked *before* destructive work so
  /// re-authentication can happen first.
  Future<bool> needsRecentLogin();

  /// Re-authenticates the current user to satisfy the recent-login
  /// requirement. Email/password accounts require [password]; when it is
  /// null the provider (Google) flow is used.
  Future<void> reauthenticate({String? password});

  Future<void> forgotPassword({required String email});

  Future<AppUser?> getCurrentUser();

  /// Emits the current user on every auth state change (`null` when
  /// signed out). Router redirects will consume this.
  Stream<AppUser?> authStateChanges();
}
