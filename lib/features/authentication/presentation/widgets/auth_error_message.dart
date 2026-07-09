import '../../domain/exceptions/auth_exception.dart';

/// User-facing copy for authentication failures.
///
/// Lives in presentation because wording is a UI concern; the domain
/// exposes only typed reasons.
extension AuthErrorMessage on AuthException {
  String get userMessage {
    return switch (reason) {
      AuthErrorReason.invalidCredentials =>
        "That email and password don't match. Please try again.",
      AuthErrorReason.emailAlreadyInUse =>
        'An account already exists with this email. Try logging in instead.',
      AuthErrorReason.weakPassword =>
        'That password is too easy to guess. Try a longer one.',
      AuthErrorReason.network =>
        "You seem to be offline. Check your connection and try again.",
      // Handled silently by the notifier; present only for exhaustiveness.
      AuthErrorReason.cancelled => 'Sign-in was cancelled.',
      AuthErrorReason.tooManyRequests =>
        "We just sent one — give it a moment, then try again if it "
            "hasn't arrived.",
      AuthErrorReason.sessionExpired =>
        'Your session has expired. Please log in again.',
      AuthErrorReason.requiresRecentLogin =>
        'For security, this needs a fresh login. Please log out, log '
            'back in, and try again.',
      AuthErrorReason.unknown =>
        'Something went wrong on our side. Please try again.',
    };
  }
}
