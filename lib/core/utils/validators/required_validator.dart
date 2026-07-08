/// Generic required-input validation.
///
/// Returns `null` when valid, otherwise [message].
abstract final class RequiredValidator {
  static String? validate(
    String? value, {
    String message = 'This field is required.',
  }) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }
}
