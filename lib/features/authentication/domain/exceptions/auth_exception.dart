/// Why an authentication operation failed, in domain terms.
enum AuthErrorReason {
  invalidCredentials,
  emailAlreadyInUse,
  weakPassword,
  network,

  /// The user dismissed a provider sign-in flow (e.g. the Google account
  /// picker). Not an error condition; presentation handles it silently.
  cancelled,

  /// Firebase rate limiting (e.g. requesting verification emails in
  /// quick succession).
  tooManyRequests,

  /// The current session is gone or no longer valid.
  sessionExpired,

  /// The operation is security-sensitive and Firebase requires a recent
  /// login (e.g. account deletion long after signing in).
  requiresRecentLogin,
  unknown,
}

/// Domain-level authentication failure.
///
/// The data layer maps SDK-specific errors (e.g. `FirebaseAuthException`)
/// to this type, so presentation and domain code never depend on Firebase.
class AuthException implements Exception {
  const AuthException(this.reason, [this.message]);

  final AuthErrorReason reason;

  /// Optional detail, safe to log. UI copy should be derived from [reason].
  final String? message;

  @override
  String toString() =>
      'AuthException(${reason.name}${message == null ? '' : ': $message'})';
}
