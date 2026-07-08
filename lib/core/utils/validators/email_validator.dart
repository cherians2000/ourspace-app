/// Email input validation.
///
/// Returns `null` when valid, otherwise a user-facing message — the
/// contract expected by `TextFormField.validator`.
abstract final class EmailValidator {
  static final RegExp _pattern = RegExp(
    r"^[\w.!#$%&'*+/=?^`{|}~-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$",
  );

  static String? validate(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email.';
    if (!_pattern.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }
}
