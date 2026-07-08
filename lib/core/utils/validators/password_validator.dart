/// Password input validation.
///
/// Returns `null` when valid, otherwise a user-facing message.
abstract final class PasswordValidator {
  static const int minLength = 8;

  static String? validate(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Please enter a password.';
    if (password.length < minLength) {
      return 'Use at least $minLength characters.';
    }
    return null;
  }

  /// Validates that a confirmation input matches [original].
  static String? validateConfirmation(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != original) return "Passwords don't match.";
    return null;
  }
}
