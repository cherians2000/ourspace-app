/// Why an authentication operation failed, in domain terms.
enum AuthErrorReason {
  invalidCredentials,
  emailAlreadyInUse,
  weakPassword,
  network,
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
