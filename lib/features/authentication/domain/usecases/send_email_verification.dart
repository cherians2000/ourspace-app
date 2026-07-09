import '../repositories/authentication_repository.dart';

/// Re-sends the verification email to the current user.
class SendEmailVerification {
  const SendEmailVerification(this._repository);

  final AuthenticationRepository _repository;

  Future<void> call() => _repository.sendEmailVerification();
}
