import '../repositories/authentication_repository.dart';

/// Sends a password-reset email to the given address.
class ForgotPassword {
  const ForgotPassword(this._repository);

  final AuthenticationRepository _repository;

  Future<void> call({required String email}) {
    return _repository.forgotPassword(email: email);
  }
}
