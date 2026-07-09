/// Why a profile operation failed, in domain terms.
enum ProfileErrorReason {
  invalidInput,
  permissionDenied,
  network,

  /// Backend infrastructure is missing or misconfigured (e.g. the
  /// Storage bucket doesn't exist). An app-developer problem, not a
  /// user or transient problem.
  misconfigured,

  /// A security-sensitive operation (account deletion) needs a fresh
  /// login before it can proceed. For email accounts the UI should
  /// collect the password and retry.
  requiresRecentLogin,

  /// Re-authentication was attempted but rejected (e.g. wrong password).
  reauthenticationFailed,

  /// The user dismissed a re-authentication flow (e.g. the Google
  /// account picker). Not an error; handled silently.
  cancelled,
  unknown,
}

/// Domain-level profile failure.
///
/// The data layer maps SDK errors (e.g. Firestore's `FirebaseException`)
/// to this type, so upper layers never depend on Firestore.
class ProfileException implements Exception {
  const ProfileException(this.reason, [this.message]);

  final ProfileErrorReason reason;

  /// Optional detail, safe to log.
  final String? message;

  @override
  String toString() =>
      'ProfileException(${reason.name}${message == null ? '' : ': $message'})';
}
